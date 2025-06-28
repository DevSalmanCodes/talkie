import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:talkie/constants/app_constants.dart';
import 'package:talkie/models/chat_model.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/repositories/chat_repository.dart';
import 'package:talkie/repositories/methods/storage_methods.dart';
import 'package:talkie/type_defs.dart';
import 'package:talkie/utils/methods.dart';
import 'package:uuid/uuid.dart';

final chatViewModelProvider = StateNotifierProvider<ChatViewModel, bool>(
  (ref) => ChatViewModel(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(chatRepositoryProvider),
    ref.watch(firebaseAuthProvider),
    AudioRecorder(),
  ),
);

final getAllMessagesProvider = StreamProvider.family(
  (ref, String chatId) =>
      ref.watch(chatViewModelProvider.notifier).getAllMessages(chatId),
);

final getAllChatsProvider = StreamProvider.family(
  (ref, String uid) =>
      ref.watch(chatViewModelProvider.notifier).getAllChats(uid),
);
final otherUserTypingProvider =
    StreamProvider.family<bool, Map<String, String>>((ref, data) {
      final chatId = data['chatId']!;
      final otherUserId = data['otherUserId']!;
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map((doc) {
            final typingStatus =
                doc.data()?['typingStatus'] as Map<String, dynamic>?;
            return typingStatus?[otherUserId] ?? false;
          });
    });

class ChatViewModel extends StateNotifier<bool> {
  final FirebaseFirestore _firestore;
  final ChatRepository _chatRepository;
  final FirebaseAuth _auth;
  final AudioRecorder _audioRecorder;
  int seconds = 0;
  ChatViewModel(
    this._firestore,
    this._chatRepository,
    this._auth,
    this._audioRecorder,
  ) : super(false);

  Future<String> getOrCreateChat(
    String userUid,
    String currentUserUid,
    BuildContext context,
  ) async {
    final chatId = _generateChatId(userUid, currentUserUid);
    final chatRef = await _firestore.collection('chats').doc(chatId).get();

    if (!chatRef.exists) {
      ChatModel chat = ChatModel(
        id: chatId,
        participantIds: [userUid, currentUserUid],
        timestamp: Timestamp.now(),
        lastMessage: '',
        lastMessageTimestamp: Timestamp.now(),
      );
      await _firestore.collection('chats').doc(chatId).set(chat.toMap());
    }
    return chatId;
  }

  String _generateChatId(String uid1, String uid2) {
    final uids = [uid1, uid2];
    uids.sort();
    final chatId = uids.join('-');
    return chatId;
  }

  Stream<List<MessageModel>> getAllMessages(String chatId) {
    final messageDocs = _chatRepository.getAllMessages(chatId);
    return messageDocs.map(
      (data) =>
          data.map((message) => MessageModel.fromMap(message.data())).toList(),
    );
  }

  FutureVoid sendTextMessage(
    String chatId,
    String content,
    BuildContext context,
  ) async {
    final messageId = const Uuid().v4();
    final messageModel = _sendMessage(messageId, '', 'text', content);

    final res = await _chatRepository.sendTextMessage(
      chatId,
      messageModel,
      messageId,
    );
    res.fold((l) => showToast(l.message ?? errorText), (r) => null);
  }

  Stream<List<ChatModel>> getAllChats(String uid) {
    return _chatRepository
        .getAllChats(uid)
        .map(
          (data) => data.map((chat) => ChatModel.fromMap(chat.data())).toList(),
        );
  }

  FutureVoid markAsReadMessages(String chatId) async {
    await _chatRepository.markAsReadMessages(chatId);
  }

  FutureVoid sendImageMessage(
    String chatId,
    File file,
    BuildContext context,
  ) async {
    final messageId = const Uuid().v4();
    final url = await StorageMethods.uploadFileToFirebase(
      file: file,
      type: UploadType.image,
      path: 'chatPics',
      context: context,
    );
    final messageModel = _sendMessage(messageId, url ?? '', 'image', '');
    final res = await _chatRepository.sendImageMessage(
      chatId,
      messageModel,
      messageId,
    );
    res.fold((l) => showToast(l.message ?? errorText), (r) => null);
  }

  void addReactionToMessage(
    String messageId,
    String chatId,
    String reaction,
  ) async {
    _chatRepository.addReactionToMessage(messageId, chatId, reaction);
  }

  FutureVoid sendVoiceMessage(
    String chatId,
    File file,
    BuildContext context,
  ) async {
    final messageId = const Uuid().v4();
    final url = await StorageMethods.uploadFileToFirebase(
      file: file,
      type: UploadType.voice,
      path: 'chatVoices',
      context: context,
    );
    final messageModel = _sendMessage(messageId, url ?? '', 'voice', '');
    final res = await _chatRepository.sendVoiceMessage(
      chatId,
      messageModel,
      messageId,
    );
    res.fold((l) => showToast(l.message ?? errorText), (r) => null);
  }

  FutureVoid startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/${const Uuid().v4()}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: filePath);

      state = true;
    } else {
      showToast('Microphone permission denied');
    }
  }

  FutureVoid stopRecordingAndSend(String chatId, BuildContext context) async {
    if (await _audioRecorder.isRecording()) {
      final path = await _audioRecorder.stop();
      state = false;
      if (path != null) {
        final file = File(path);
        if (context.mounted) {
          sendVoiceMessage(chatId, file, context);
        }
      } else {
        showToast('Recording failed');
      }
    }
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  MessageModel _sendMessage(
    String uid,
    String url,
    String type,
    String content,
  ) {
    return MessageModel(
      id: uid,
      senderId: _auth.currentUser!.uid,
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      status: 'sent',
      type: type,
      contentUrl: url,
      reactions: {},
    );
  }

  void updateTypingStatus(String chatId, String userId, bool isTyping) {
    _chatRepository.setTypingStatus(chatId, userId, isTyping);
  }

  FutureVoid cancelRecording() async {
    if (await isRecording()) {
      _audioRecorder.cancel();
      state = false;
    }
  }

  FutureVoid deleteMessages(String chatId, List<MessageModel> messageModels) async {
    final res = await _chatRepository.deleteMessages(chatId, messageModels);
    res.fold((l) => showToast(l.message!), (r) => null);
  }
}

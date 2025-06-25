import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:talkie/constants/app_constants.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/repositories/failure.dart';
import 'package:talkie/repositories/methods/storage_methods.dart';
import 'package:talkie/services/user_service.dart';
import 'package:talkie/view_models.dart/auth_view_model.dart';

import '../type_defs.dart';

abstract class IChatRepository {
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllMessages(
    String chatId,
  );
  FutureEitherVoid sendTextMessage(
    String chaId,
    MessageModel messageModel,
    String docId,
  );
  FutureEitherVoid sendImageMessage(
    String chatId,
    MessageModel messageModel,
    String docId,
  );
  FutureEitherVoid sendVoiceMessage(
    String chatId,
    MessageModel messageModel,
    String docId,
  );

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllChats(
    String uid,
  );

  FutureEitherVoid markAsReadMessages(String chaId);
  FutureVoid addReactionToMessage(
    String messageId,
    String chatId,
    String reaction,
  );
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping);
}

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(userServiceProvider),
  ),
);

class ChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;
  ChatRepository(this._firestore, this._auth, this._userService);
  @override
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllMessages(
    String chatId,
  ) {
    final chatRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots();
    return chatRef.map((data) => data.docs);
  }

  @override
  FutureEitherVoid sendTextMessage(
    String chatId,
    MessageModel messageModel,
    String docId,
  ) async {
    try {
      await _sendMessage(chatId, docId, messageModel);

      _updateLastMessage(chatId, messageModel.content, 'text');
      return right(null);
    } on FirebaseException catch (e, st) {
      return left(Failure(e.message, st.toString()));
    }
  }

  @override
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllChats(
    String uid,
  ) {
    final res = _firestore
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .snapshots();
    return res.map((chats) => chats.docs);
  }

  @override
  FutureEitherVoid markAsReadMessages(String chatId) async {
    try {
      final messagesDocs = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      final batch = _firestore.batch();

      for (var doc in messagesDocs.docs) {
        if (doc.data()['senderId'] != _auth.currentUser!.uid &&
            doc.data()['status'] != 'seen') {
          batch.update(
            _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc(doc.id),
            {'status': 'seen'},
          );
        }
      }
      await batch.commit();
    } on FirebaseException catch (e, st) {
      return left(Failure(e.message, st.toString()));
    } catch (e, st) {
      return left(Failure(e.toString(), st.toString()));
    }
    return left(Failure(errorText, ''));
  }

  @override
  FutureEitherVoid sendImageMessage(
    String chatId,
    MessageModel messageModel,
    String docId,
  ) async {
    try {
      await _sendMessage(chatId, docId, messageModel);
      _updateLastMessage(chatId, '📷  Photo', 'image');
      return right(null);
    } on FirebaseException catch (e, st) {
      return left(Failure(e.message, st.toString()));
    } catch (e, st) {
      return left(Failure(e.toString(), st.toString()));
    }
  }

  @override
  FutureEitherVoid sendVoiceMessage(
    String chatId,
    MessageModel messageModel,
    String docId,
  ) async {
    try {
      await _sendMessage(chatId, docId, messageModel);
      _updateLastMessage(chatId, '🎤 Voice', 'voice');
      return right(null);
    } on FirebaseException catch (e, st) {
      return left(Failure(e.message, st.toString()));
    } catch (e, st) {
      return left(Failure(e.toString(), st.toString()));
    }
  }

  FutureEitherVoid _updateLastMessage(
    String chatId,
    String lastMessage,
    String lastMessageType,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessage,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      return right(null);
    } on FirebaseException catch (e, st) {
      return left(Failure(e.message, st.toString()));
    } catch (e, st) {
      return left(Failure(e.toString(), st.toString()));
    }
  }

  @override
  FutureVoid addReactionToMessage(
    String messageId,
    String chatId,
    String reaction,
  ) async {
    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final doc = await docRef.get();

    final docData = doc.data();
    if (docData == null || !docData.containsKey('reactions')) return;

    final reactions = (docData['reactions'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, List<String>.from(value as List<dynamic>)),
    );
    final currentUserUid = _auth.currentUser!.uid;
    bool isUpdated = false;
    if (reactions.containsKey(reaction)) {
      final userList = reactions[reaction]!;
      if (!userList.contains(currentUserUid)) {
        userList.add(currentUserUid);
        isUpdated = true;
      } else {
        userList.remove(currentUserUid);
        if (userList.isEmpty) {
          reactions.remove(reaction);
        }
        isUpdated = true;
      }
    } else {
      reactions.forEach((key, value) {
        if (value.contains(currentUserUid)) {
          value.remove(currentUserUid);
        }
      });
      reactions.removeWhere((key, value) => value.isEmpty);
      reactions[reaction] = [currentUserUid];

      isUpdated = true;
    }
    if (isUpdated) {
      await docRef.update({'reactions': reactions});
    }
  }



  FutureVoid _sendMessage(
    String chatId,
    String docId,
    MessageModel messageModel,
  ) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(docId)
        .set(messageModel.toMap());
  }

  @override
  Future<void> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.set({
      'typing': {userId: isTyping},
    }, SetOptions(merge: true));
  }
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/constants/app_constants.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/utils/methods.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/widgets/custom_app_bar.dart';
import 'package:talkie/widgets/loader.dart';
import 'package:talkie/widgets/message_item.dart';
import '../utils/date_time.dart';

class ChatView extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel userModel;

  const ChatView({super.key, required this.chatId, required this.userModel});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _scrollController = ScrollController();
  late TextEditingController _messageController;
  late String _currentUserUid;
  File? _file;
  bool isTyping = false;
  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _currentUserUid = ref.read(firebaseAuthProvider).currentUser!.uid;
    _markAsReadMessages();
  }

  void _onSendMessage() {
    final message = _messageController.text.trim();
    if (_file != null) {
      ref
          .read(chatViewModelProvider.notifier)
          .sendImageMessage(widget.chatId, _file!, context);
      setState(() => _file = null);
    } else if (message.isNotEmpty) {
      ref
          .read(chatViewModelProvider.notifier)
          .sendTextMessage(widget.chatId, message, context);
    }
    _messageController.clear();
    _updateTypingStatus(false);
  }

  void _onPickImage() async {
    final image = await pickImage();
    if (image != null) setState(() => _file = image);
  }

  void _jumpToLatestMessage() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markAsReadMessages() {
    ref.read(chatViewModelProvider.notifier).markAsReadMessages(widget.chatId);
  }

  void _updateTypingStatus(bool typing) {
    ref.read(isMessageEmptyProvider.notifier).state =
        _messageController.text.isEmpty ||
        _messageController.text.trim().isEmpty;
    _messageController.text.isEmpty || _messageController.text.trim().isEmpty;
    setState(() {});
    if (typing != isTyping) {
      isTyping = typing;
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'typingStatus.$_currentUserUid': typing,
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _updateTypingStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(getAllMessagesProvider(widget.chatId));
    final isRecording = ref.watch(chatViewModelProvider);
    final keyboardSize = MediaQuery.of(context).viewInsets.bottom;
    final isMessageEmpty = ref.watch(isMessageEmptyProvider.notifier).state;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.userModel.username,
        fontSize: 16.0,
        leading: CircleAvatar(
          backgroundImage: widget.userModel.profilePic!.isNotEmpty
              ? CachedNetworkImageProvider(widget.userModel.profilePic!)
              : const NetworkImage(defaultProfilePic),
        ),
        lastSeen: widget.userModel.isOnline
            ? 'Active now'
            : 'Last seen: ${formatDate(DateTime.fromMillisecondsSinceEpoch(int.parse(widget.userModel.lastSeen.toString())))}',
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, chatSnapshot) {
                bool otherUserTyping = false;
                if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                  final chatData =
                      chatSnapshot.data!.data() as Map<String, dynamic>;
                  final typingMap =
                      chatData['typingStatus'] as Map<String, dynamic>? ?? {};
                  otherUserTyping = typingMap[widget.userModel.uid] == true;
                }

                return messagesAsyncValue.when(
                  data: (messages) {
                    messages.sort(
                      (a, b) => int.parse(
                        a.timestamp,
                      ).compareTo(int.parse(b.timestamp)),
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _jumpToLatestMessage();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length + (otherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && otherUserTyping) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              children: [
                                LottieBuilder.asset(
                                  'assets/indicator.json',
                                  height: 50,
                                ),
                              ],
                            ),
                          );
                        }

                        final message = messages[index];
                        final messageDate = DateTime.fromMillisecondsSinceEpoch(
                          int.parse(message.timestamp),
                        );
                        final isSender = message.senderId == _currentUserUid;
                        final showDateHeader =
                            index == 0 ||
                            DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(messages[index - 1].timestamp),
                                ).day !=
                                messageDate.day;

                        return MessageItem(
                          message: message,
                          isSender: isSender,
                          showDateHeader: showDateHeader,
                          chatId: widget.chatId,
                          currentUserUid: _currentUserUid,
                        );
                      },
                    );
                  },
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  loading: () => const Loader(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          bottom: keyboardSize + 8.0,
          right: 8.0,
          left: 8.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _onPickImage,
              icon: const Icon(LucideIcons.image, color: Colors.white),
            ),
            Expanded(
              child: _file == null
                  ? TextFormField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (text) => _updateTypingStatus(text.isNotEmpty),
                      decoration: InputDecoration(
                        hintText: isRecording ? "Recording..." : "Message...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_file!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _file = null),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            if ((isMessageEmpty) && _file == null)
              GestureDetector(
                onLongPressStart: (_) async {
                  await ref
                      .read(chatViewModelProvider.notifier)
                      .startRecording();
                },
                onLongPressEnd: (_) async {
                  await ref
                      .read(chatViewModelProvider.notifier)
                      .stopRecordingAndSend(widget.chatId, context);
                },
                child: const CircleAvatar(
                  backgroundColor: ColorConstants.senderChatColor,
                  child: Icon(Icons.mic, color: Colors.white),
                ),
              )
            else
              IconButton(
                onPressed: _onSendMessage,
                icon: Icon(
                  LucideIcons.send,
                  color: ColorConstants.senderChatColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

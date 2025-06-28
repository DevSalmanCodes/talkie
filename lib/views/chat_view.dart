import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/constants/app_constants.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/providers/recording_timer_provider.dart'
    as recordingtimer;
import 'package:talkie/utils/methods.dart';
import 'package:talkie/utils/play_sounds.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/widgets/custom_app_bar.dart';
import 'package:talkie/widgets/loader.dart';
import 'package:talkie/widgets/message_item.dart';
import 'package:talkie/widgets/reaction_overlay_controller.dart';
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
  bool _isTyping = false;
  String? _lastMessageId;

  double _dragDistance = 0;
  bool _cancelRecording = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _currentUserUid = ref.read(firebaseAuthProvider).currentUser!.uid;
    _markAsReadMessages();
    _lastMessageId = null;
  }

  void _onSendMessage() {
    final message = _messageController.text.trim();
    if (_file != null) {
      ref
          .read(chatViewModelProvider.notifier)
          .sendImageMessage(widget.chatId, _file!, context);
      setState(() => _file = null);
    } else if (message.isNotEmpty && _file == null) {
      ref
          .read(chatViewModelProvider.notifier)
          .sendTextMessage(widget.chatId, message, context);
    }
    playSound('sending.mp3');
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
    ref.read(isMessageEmptyProvider.notifier).state = _messageController.text
        .trim()
        .isEmpty;
    setState(() {});
    if (typing != _isTyping) {
      _isTyping = typing;
      ref
          .read(chatViewModelProvider.notifier)
          .updateTypingStatus(widget.chatId, _currentUserUid, typing);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteDialog(List<MessageModel> selectedMessages) async {
    final String dialogContent = selectedMessages.length > 1
        ? ' Are you sure you want to delete ${selectedMessages.length} messages?'
        : 'Are you sure want to delete this message?';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: const Text('Logout'),
                content: Text(dialogContent),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Delete'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              )
            : AlertDialog(
                title: const Text('Logout'),
                content: Text(dialogContent),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
      },
    );

    if (shouldDelete == true) {
      if (context.mounted) {
        ref
            .read(chatViewModelProvider.notifier)
            .deleteMessages(widget.chatId, selectedMessages);
        ref.read(selectedMessagesProvider.notifier).state = [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(getAllMessagesProvider(widget.chatId));
    final isRecording = ref.watch(chatViewModelProvider);
    final keyboardSize = MediaQuery.of(context).viewInsets.bottom;
    final isMessageEmpty = ref.watch(isMessageEmptyProvider.notifier).state;
    final recordingTimerProviderState = ref.watch(
      recordingtimer.recordingTimerProvider,
    );
    final recordingTimerProvider = ref.read(
      recordingtimer.recordingTimerProvider.notifier,
    );
    final selectedMessages = ref.watch(selectedMessagesProvider);
    return GestureDetector(
      onTap: () => ref.read(selectedMessagesProvider.notifier).state = [],
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) return;
          // Clear selected messages
          if (ref.read(selectedMessagesProvider).isNotEmpty) {
            ref.read(selectedMessagesProvider.notifier).state = [];
            removeReactionOverlay();
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            actionItemsList: [
              if (selectedMessages.isNotEmpty)
                IconButton(
                  icon: Icon(LucideIcons.trash2, color: Colors.redAccent),
                  onPressed: () => _showDeleteDialog(selectedMessages),
                ),
            ],
            title: widget.userModel.username,
            fontSize: 16.0,
            leading: CircleAvatar(
              backgroundImage: widget.userModel.profilePic!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.userModel.profilePic!)
                  : const NetworkImage(defaultProfilePic),
            ),
            lastSeen: widget.userModel.isOnline
                ? 'Active now'
                : 'Last seen: ${formatDate(DateTime.parse(widget.userModel.lastSeen))} at ${formatDateTime(DateTime.parse(widget.userModel.lastSeen))}',
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
                          chatData['typingStatus'] as Map<String, dynamic>? ??
                          {};
                      otherUserTyping = typingMap[widget.userModel.uid] == true;
                    }

                    return messagesAsyncValue.when(
                      data: (messages) {
                        messages.sort(
                          (a, b) => int.parse(
                            a.timestamp,
                          ).compareTo(int.parse(b.timestamp)),
                        );
                        final lastMessage = messages.isNotEmpty
                            ? messages.last
                            : null;
                        if (lastMessage != null &&
                            lastMessage.senderId !=
                                ref
                                    .read(firebaseAuthProvider)
                                    .currentUser
                                    ?.uid &&
                            _lastMessageId != lastMessage.id) {
                          playSound('incoming.mp3');
                          _lastMessageId = lastMessage.id;
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          _jumpToLatestMessage();
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              messages.length + (otherUserTyping ? 1 : 0),
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
                            final messageDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(message.timestamp),
                                );
                            final isSender =
                                message.senderId == _currentUserUid;
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
              right: 10.0,
              left: 10.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: !isRecording ? 4 : 10,
                      vertical: !isRecording ? 4 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        if (!isRecording) ...[
                          IconButton(
                            onPressed: _onPickImage,
                            icon: const Icon(
                              LucideIcons.image,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: _file == null
                                ? TextFormField(
                                    readOnly: isRecording,
                                    controller: _messageController,
                                    style: const TextStyle(color: Colors.white),
                                    onChanged: (text) =>
                                        _updateTypingStatus(text.isNotEmpty),
                                    decoration: InputDecoration(
                                      hintText: "Message",
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                      ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          onTap: () =>
                                              setState(() => _file = null),
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
                        ],

                        if (isRecording)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _cancelRecording ? 1.0 : 0.7,
                            child: Row(
                              children: [
                                Icon(LucideIcons.mic, color: Colors.red),
                                SizedBox(width: 8.0),
                                Text(
                                  _formatDuration(recordingTimerProviderState),
                                ),
                                SizedBox(width: 20.0),

                                Icon(Icons.arrow_back_ios, color: Colors.white),
                                Text(
                                  "Slide to cancel",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onLongPressStart: isMessageEmpty
                      ? (_) async {
                          _cancelRecording = false;
                          await HapticFeedback.vibrate();
                          await ref
                              .read(chatViewModelProvider.notifier)
                              .startRecording();
                          recordingTimerProvider.start();
                        }
                      : null,
                  onLongPressMoveUpdate: isMessageEmpty
                      ? (details) async {
                          setState(() {
                            _dragDistance += details.offsetFromOrigin.dx;
                            if (_dragDistance < -100) {
                              _cancelRecording = true;
                              ref
                                  .read(chatViewModelProvider.notifier)
                                  .cancelRecording();
                              showToast('Recording cancelled');
                            }
                          });
                        }
                      : null,
                  onLongPressEnd: isMessageEmpty
                      ? (_) async {
                          if (_cancelRecording) {
                            await ref
                                .read(chatViewModelProvider.notifier)
                                .cancelRecording();
                            recordingTimerProvider.stop();
                          } else {
                            await ref
                                .read(chatViewModelProvider.notifier)
                                .stopRecordingAndSend(widget.chatId, context);
                            recordingTimerProvider.stop();
                          }
                          _dragDistance = 0;
                        }
                      : null,
                  onTap: () {
                    if (!isMessageEmpty) {
                      _onSendMessage();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: !isRecording ? 25.0 : 40,
                        backgroundColor: !isRecording
                            ? ColorConstants.senderChatColor
                            : Colors.red,
                        child: Icon(
                          isMessageEmpty && _file == null
                              ? LucideIcons.mic
                              : LucideIcons.send,
                          color: Colors.white,
                          size: !isRecording ? 24 : 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }
}

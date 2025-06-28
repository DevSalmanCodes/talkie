import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/utils/date_time.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/widgets/loader.dart';
import 'package:talkie/widgets/reaction_overlay_controller.dart';
import 'package:voice_message_package/voice_message_package.dart';
import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';

/// Keeps track of currently open reaction overlay

class ChatBubble extends ConsumerWidget {
  final bool isSender;
  final MessageModel messageModel;
  final String currentUserUid;
  final String chatId;

  const ChatBubble({
    super.key,
    required this.isSender,
    required this.messageModel,
    required this.currentUserUid,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isText = messageModel.type == 'text';
    final isImage = messageModel.type == 'image';
    final isVoice = messageModel.type == 'voice';
    final bubbleColor = isSender
        ? ColorConstants.senderChatColor
        : ColorConstants.receiverChatColor;
    final selectedMessages = ref.watch(selectedMessagesProvider.notifier);
    final auth = ref.watch(firebaseAuthProvider);
    print(selectedMessages.state.length);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            final selected = ref.read(selectedMessagesProvider);
            if (selected.isNotEmpty) {
              final isAlreadySelected = selected.contains(messageModel);
              if (isAlreadySelected) {
                ref.read(selectedMessagesProvider.notifier).state = selected
                    .where((message) => message.id != messageModel.id)
                    .toList();
              } else if (auth.currentUser?.uid == messageModel.senderId) {
                ref.read(selectedMessagesProvider.notifier).state = [
                  ...selected,
                  messageModel,
                ];
              }
            }
          },
          onLongPress: () {
            final selected = ref.read(selectedMessagesProvider);

            if (selected.isEmpty &&
                messageModel.senderId == auth.currentUser?.uid) {
              ref.read(selectedMessagesProvider.notifier).state = [
                ...selected,
                messageModel,
              ];
            }

            activeReactionOverlayEntry?.remove();
            final renderBox = context.findRenderObject() as RenderBox?;
            final overlay = Overlay.of(context);
            if (renderBox == null) return;

            final position = renderBox.localToGlobal(Offset.zero);

            activeReactionOverlayEntry = OverlayEntry(
              builder: (_) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  removeReactionOverlay();
                },

                child: Stack(
                  children: [
                    if (selected.isEmpty)
                      ReactionOverlay(
                        position: position,
                        onReactionSelected: (emoji) {
                          removeReactionOverlay();
                          ref
                              .read(chatViewModelProvider.notifier)
                              .addReactionToMessage(
                                messageModel.id,
                                chatId,
                                emoji,
                              );
                          selectedMessages.state = [];
                        },
                      ),
                  ],
                ),
              ),
            );

            overlay.insert(activeReactionOverlayEntry!);
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: selectedMessages.state.contains(messageModel)
                  ? Color(0xFF3A3B4C)
                  : null,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: isSender
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isText)
                  Container(
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14.0),
                        topRight: Radius.circular(14.0),
                        bottomLeft: Radius.circular(14.0),
                        bottomRight: isSender
                            ? Radius.zero
                            : Radius.circular(14.0),
                      ),
                    ),
                    child: Text(
                      messageModel.content,
                      style: TextStyleConstants.regularTextStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isImage) _buildImageWidget(context, messageModel),
                if (isVoice) _buildVoiceWidget(messageModel),
                const SizedBox(height: 4),
                _buildTimeAndStatus(
                  DateTime.fromMillisecondsSinceEpoch(
                    int.parse(messageModel.timestamp),
                  ),
                ),
                if (messageModel.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: messageModel.reactions.entries
                          .map(
                            (e) => Text(
                              e.key,
                              style: const TextStyle(fontSize: 18),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAndStatus(DateTime timestamp) {
    final formattedTime = formatDateTime(timestamp);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isSender
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Text(
          formattedTime,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        if (isSender) ...[
          const SizedBox(width: 6),
          Icon(
            messageModel.status == 'sent' ? Icons.check : Icons.done_all,
            size: 15,
            color: messageModel.status == 'seen' ? Colors.blue : Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context, MessageModel messageModel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          RouteNames.photoView,
          arguments: messageModel.contentUrl,
        ),
        child: CachedNetworkImage(
          imageUrl: messageModel.contentUrl,
          fit: BoxFit.cover,
          height: 180,
          width: 180,
          placeholder: (context, url) => const Loader(),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildVoiceWidget(MessageModel messageModel) {
    return VoiceMessageView(
      controller: VoiceController(
        audioSrc: messageModel.contentUrl,
        maxDuration: const Duration(minutes: 5),
        isFile: false,
        onComplete: () {},
        onPause: () {},
        onPlaying: () {},
      ),
    );
  }
}

class ReactionOverlay extends StatelessWidget {
  final Offset position;
  final void Function(String emoji) onReactionSelected;

  const ReactionOverlay({
    super.key,
    required this.position,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final top = position.dy < 100 ? position.dy + 60 : position.dy - 60;
    final left = position.dx.clamp(20, screenSize.width - 200);

    return Positioned(
      top: top,
      left: left.toDouble(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A35),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
              return GestureDetector(
                onTap: () => onReactionSelected(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

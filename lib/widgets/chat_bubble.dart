import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/utils/date_time.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/widgets/loader.dart';
import 'package:voice_message_package/voice_message_package.dart';
import '../constants/color_constants.dart';
import '../constants/text_style_constants.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showReactionPicker(
            context,
            messageModel.id,
            chatId,
            ref,
            messageModel,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _buildTextWidget(messageModel),
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
                          (e) =>
                              Text(e.key, style: const TextStyle(fontSize: 18)),
                        )
                        .toList(),
                  ),
                ),
            ],
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

  Widget _buildTextWidget(MessageModel messageModel) {
    return Text(
      messageModel.content,
      style: TextStyleConstants.regularTextStyle.copyWith(color: Colors.white),
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

void _showReactionPicker(
  BuildContext context,
  String messageId,
  String chatId,
  WidgetRef ref,
  MessageModel messageModel,
) {
  showModalBottomSheet(
    backgroundColor: const Color(0xFF2A2A35),
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((reaction) {
            return IconButton(
              icon: Text(reaction, style: const TextStyle(fontSize: 26)),
              onPressed: () {
                Navigator.pop(context);
                Future.microtask(() {
                  if (ref.context.mounted) {
                    ref
                        .read(chatViewModelProvider.notifier)
                        .addReactionToMessage(messageId, chatId, reaction);
                  }
                });
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

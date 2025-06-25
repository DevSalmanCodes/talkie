import 'package:flutter/material.dart';
import 'package:talkie/constants/text_style_constants.dart';
import 'package:talkie/models/message_model.dart';
import 'package:talkie/utils/date_time.dart';
import 'package:talkie/widgets/chat_bubble.dart';

class MessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isSender;
  final bool showDateHeader;
  final String chatId;
  final String currentUserUid;

  const MessageItem({
    super.key,
    required this.message,
    required this.isSender,
    required this.showDateHeader,
    required this.chatId,
    required this.currentUserUid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatDate(
                    DateTime.fromMillisecondsSinceEpoch(
                      int.parse(message.timestamp),
                    ),
                  ),
                  style: TextStyleConstants.semiBoldTextStyle.copyWith(
                    fontSize: 13,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ChatBubble(
            isSender: isSender,
            messageModel: message,
            currentUserUid: currentUserUid,
            chatId: chatId,
          ),
        ),
      ],
    );
  }
}

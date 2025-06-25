import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/utils/date_time.dart';
import '../constants/size_constants.dart';
import '../constants/text_style_constants.dart';

class ChatListTile extends StatelessWidget {
  final String title;
  final Widget subtitleText;
  final ImageProvider backgroundImage;
  final bool isOnline;
  final Timestamp lastMessageTimestamp;
  final VoidCallback? onTap;

  const ChatListTile({
    super.key,
    required this.title,
    required this.subtitleText,
    required this.backgroundImage,
    required this.isOnline,
    required this.onTap,
    required this.lastMessageTimestamp,
  });

  static const double largeRadius = SizeConstants.largeRadius;
  static const double smallPadding = SizeConstants.smallPadding;
  static final TextStyle regularTextStyle = TextStyleConstants.regularTextStyle;
  static final TextStyle semiBoldTextStyle =
      TextStyleConstants.semiBoldTextStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: ColorConstants.scaffoldBackgroundColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: largeRadius + 4,
                  backgroundImage: backgroundImage,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: semiBoldTextStyle.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  subtitleText,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatDateTime(
                DateTime.fromMillisecondsSinceEpoch(
                  lastMessageTimestamp.millisecondsSinceEpoch,
                ),
              ),
              style: regularTextStyle.copyWith(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final Timestamp timestamp;
  final Timestamp? lastMessageTimestamp;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.timestamp,
    required this.lastMessageTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}

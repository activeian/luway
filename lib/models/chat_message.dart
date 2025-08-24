import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? carPlateNumber;
  final String? carBrand;
  final String? replyToId;
  final String? replyToMessage;
  final bool isEdited;
  final DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.carPlateNumber,
    this.carBrand,
    this.replyToId,
    this.replyToMessage,
    this.isEdited = false,
    this.editedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'carPlateNumber': carPlateNumber,
      'carBrand': carBrand,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  factory ChatMessage.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessage(
      id: id,
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      carPlateNumber: json['carPlateNumber'],
      carBrand: json['carBrand'],
      replyToId: json['replyToId'],
      replyToMessage: json['replyToMessage'],
      isEdited: json['isEdited'] ?? false,
      editedAt: (json['editedAt'] as Timestamp?)?.toDate(),
    );
  }
}

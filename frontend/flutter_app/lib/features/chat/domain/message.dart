import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String messageType;
  final String content;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String? senderUsername;
  final String? senderDisplayName;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.messageType = 'TEXT',
    required this.content,
    this.metadata = const {},
    required this.createdAt,
    this.senderUsername,
    this.senderDisplayName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: json['message_type'] as String? ?? 'TEXT',
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String,
      senderUsername: json['sender_username'] as String?,
      senderDisplayName: json['sender_display_name'] as String?,
    );
  }

  String get senderName => senderDisplayName ?? senderUsername ?? 'Unknown';
  bool get isText => messageType == 'TEXT';

  DateTime get dateTime => DateTime.parse(createdAt);

  @override
  List<Object?> get props => [id, roomId, senderId, content, createdAt];
}

import 'package:equatable/equatable.dart';

class RoomMember extends Equatable {
  final String id;
  final String userId;
  final String role;
  final String joinedAt;
  final String username;
  final String? displayName;
  final String email;

  const RoomMember({
    required this.id,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.username,
    this.displayName,
    required this.email,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: json['joined_at'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String,
    );
  }

  String get displayNameOrUsername => displayName ?? username;

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';

  String get roleLabel {
    switch (role) {
      case 'OWNER':
        return 'Owner';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Member';
    }
  }

  @override
  List<Object?> get props => [id, userId, role];
}

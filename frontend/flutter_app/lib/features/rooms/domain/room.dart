import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String createdBy;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;
  final int memberCount;
  final String? userRole;

  const Room({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdBy,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
    this.userRole,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      memberCount: json['member_count'] as int? ?? 0,
      userRole: json['user_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  Room copyWith({
    String? name,
    String? description,
    int? memberCount,
    String? userRole,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      inviteCode: inviteCode,
      createdBy: createdBy,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      memberCount: memberCount ?? this.memberCount,
      userRole: userRole ?? this.userRole,
    );
  }

  bool get isOwner => userRole == 'OWNER';
  bool get isAdmin => userRole == 'ADMIN';
  bool get isOwnerOrAdmin => isOwner || isAdmin;

  String get roleLabel {
    switch (userRole) {
      case 'OWNER':
        return 'Owner';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Member';
    }
  }

  @override
  List<Object?> get props => [id, name, userRole, memberCount];
}

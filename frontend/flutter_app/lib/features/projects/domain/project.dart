import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String workspaceId;
  final String userId;
  final String name;
  final String? description;
  final String status;
  final String? color;
  final String? icon;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final String? workspaceName;

  const Project({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.name,
    this.description,
    this.status = 'active',
    this.color,
    this.icon,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.workspaceName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'active',
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      workspaceName: json['workspace_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'workspace_id': workspaceId,
        'name': name,
        'description': description,
        'status': status,
        'color': color,
        'icon': icon,
      };

  Project copyWith({
    String? name,
    String? description,
    String? status,
    String? color,
    String? icon,
    bool? isArchived,
    String? workspaceName,
  }) {
    return Project(
      id: id,
      workspaceId: workspaceId,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
      workspaceName: workspaceName ?? this.workspaceName,
    );
  }

  static const statuses = ['active', 'on_hold', 'completed'];

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'on_hold':
        return 'On Hold';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id, name, status, isArchived];
}

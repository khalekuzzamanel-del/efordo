import 'package:equatable/equatable.dart';

class Workspace extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final int? projectCount;

  const Workspace({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.projectCount,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      projectCount: json['project_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
      };

  Workspace copyWith({
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isArchived,
    int? projectCount,
  }) {
    return Workspace(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
      projectCount: projectCount ?? this.projectCount,
    );
  }

  @override
  List<Object?> get props => [id, name, isArchived];
}

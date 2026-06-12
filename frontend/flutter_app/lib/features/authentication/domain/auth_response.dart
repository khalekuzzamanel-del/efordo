import 'package:equatable/equatable.dart';

class AuthResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user.toJson(),
      };

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? displayName;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'display_name': displayName,
      };

  String get displayNameOrUsername => displayName ?? username;

  @override
  List<Object?> get props => [id, email, username, displayName];
}

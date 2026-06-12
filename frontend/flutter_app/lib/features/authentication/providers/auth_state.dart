import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? username;
  final String? email;
  final String? displayName;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.username,
    this.email,
    this.displayName,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? username,
    String? email,
    String? displayName,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  String get displayNameOrUsername => displayName ?? username ?? 'User';
  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [
        status,
        accessToken,
        refreshToken,
        userId,
        username,
        email,
        displayName,
        errorMessage,
      ];
}

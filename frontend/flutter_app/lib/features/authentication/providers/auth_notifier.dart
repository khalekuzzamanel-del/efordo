import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../data/auth_api_service.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authApiServiceProvider),
    ref.read(secureStorageServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._apiService, this._secureStorage)
      : super(const AuthState());

  /// Check if a session exists and restore it
  Future<void> tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final token = await _secureStorage.read(AppConstants.authTokenKey);
      final refreshToken =
          await _secureStorage.read(AppConstants.refreshTokenKey);

      if (token == null || refreshToken == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
        return;
      }

      // Verify token is still valid by calling /auth/me
      final userData = await _apiService.getMe(token);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: token,
        refreshToken: refreshToken,
        userId: userData['id'] as String?,
        username: userData['username'] as String?,
        email: userData['email'] as String?,
        displayName: userData['display_name'] as String?,
        clearError: true,
      );
    } catch (e) {
      // Token expired or invalid - clear stored tokens
      await _secureStorage.delete(AppConstants.authTokenKey);
      await _secureStorage.delete(AppConstants.refreshTokenKey);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }

  /// Login with username or email
  Future<void> login(String identifier, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    );

    try {
      final response = await _apiService.login(
        identifier: identifier,
        password: password,
      );

      // Persist tokens securely
      await _secureStorage.save(
        AppConstants.authTokenKey,
        response.accessToken,
      );
      await _secureStorage.save(
        AppConstants.refreshTokenKey,
        response.refreshToken,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
        username: response.user.username,
        email: response.user.email,
        displayName: response.user.displayName,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Register a new user
  Future<void> register(
      String username, String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
    );

    try {
      await _apiService.register(
        username: username,
        email: email,
        password: password,
      );

      // Auto-login after successful registration
      await login(email, password);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (state.accessToken != null) {
        await _apiService.logout(state.accessToken!);
      }
    } catch (_) {
      // Continue with local cleanup even if API call fails
    }

    // Clear stored tokens
    await _secureStorage.delete(AppConstants.authTokenKey);
    await _secureStorage.delete(AppConstants.refreshTokenKey);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _parseError(Object error) {
    final message = error.toString();
    if (message.contains('Invalid credentials')) {
      return 'Invalid username/email or password';
    }
    if (message.contains('already taken')) {
      return 'Username or email is already registered';
    }
    if (message.contains('already registered')) {
      return 'Email is already registered';
    }
    return 'Something went wrong. Please try again.';
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_service.dart';
import '../domain/auth_response.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return AuthApiService(dio.dio);
});

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    if (response.statusCode != 201) {
      throw Exception(response.data['message'] ?? 'Registration failed');
    }
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'Login failed');
    }
    return AuthResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user');
    }
    return response.data['user'] as Map<String, dynamic>;
  }

  Future<void> logout(String token) async {
    await _dio.post(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}

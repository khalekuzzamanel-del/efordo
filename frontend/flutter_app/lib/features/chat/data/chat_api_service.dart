import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_service.dart';
import '../domain/message.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return ChatApiService(dio.dio);
});

class ChatApiService {
  final Dio _dio;

  ChatApiService(this._dio);

  Future<Map<String, dynamic>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/rooms/$roomId/messages',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Message> sendMessage(String roomId, String content) async {
    final response = await _dio.post(
      '/rooms/$roomId/messages',
      data: {'content': content},
    );
    return Message.fromJson(response.data);
  }
}

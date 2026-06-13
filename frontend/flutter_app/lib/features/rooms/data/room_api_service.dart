import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_service.dart';
import '../domain/room.dart';
import '../domain/room_member.dart';

final roomApiServiceProvider = Provider<RoomApiService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return RoomApiService(dio.dio);
});

class RoomApiService {
  final Dio _dio;

  RoomApiService(this._dio);

  Future<List<Room>> list() async {
    final response = await _dio.get('/rooms');
    return (response.data as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<Room> get(String id) async {
    final response = await _dio.get('/rooms/$id');
    return Room.fromJson(response.data);
  }

  Future<Room> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/rooms', data: data);
    return Room.fromJson(response.data);
  }

  Future<Room> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/rooms/$id', data: data);
    return Room.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/rooms/$id');
  }

  Future<Room> join(String inviteCode) async {
    final response = await _dio.post('/rooms/join', data: {
      'invite_code': inviteCode,
    });
    return Room.fromJson(response.data);
  }

  Future<void> leave(String id) async {
    await _dio.post('/rooms/$id/leave');
  }

  Future<Map<String, dynamic>> regenerateInvite(String id) async {
    final response = await _dio.post('/rooms/$id/regenerate-invite');
    return response.data as Map<String, dynamic>;
  }

  Future<void> transferOwnership(String id, String newOwnerId) async {
    await _dio.post('/rooms/$id/transfer-ownership', data: {
      'new_owner_id': newOwnerId,
    });
  }

  Future<List<RoomMember>> getMembers(String roomId) async {
    final response = await _dio.get('/rooms/$roomId/members');
    return (response.data as List).map((e) => RoomMember.fromJson(e)).toList();
  }

  Future<void> promoteMember(String roomId, String userId) async {
    await _dio.post('/rooms/$roomId/members/$userId/promote');
  }

  Future<void> demoteMember(String roomId, String userId) async {
    await _dio.post('/rooms/$roomId/members/$userId/demote');
  }

  Future<void> removeMember(String roomId, String userId) async {
    await _dio.post('/rooms/$roomId/members/$userId/remove');
  }
}

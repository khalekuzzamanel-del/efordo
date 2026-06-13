import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_api_service.dart';
import '../domain/room.dart';

final roomListProvider =
    StateNotifierProvider<RoomListNotifier, AsyncValue<List<Room>>>((ref) {
  return RoomListNotifier(ref.read(roomApiServiceProvider));
});

class RoomListNotifier extends StateNotifier<AsyncValue<List<Room>>> {
  final RoomApiService _api;

  RoomListNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final rooms = await _api.list();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> join(String inviteCode) async {
    try {
      await _api.join(inviteCode);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> leave(String roomId) async {
    try {
      await _api.leave(roomId);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

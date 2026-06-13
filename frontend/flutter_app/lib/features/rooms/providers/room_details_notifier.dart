import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_api_service.dart';
import '../domain/room.dart';

final roomDetailsProvider =
    StateNotifierProvider.family<RoomDetailsNotifier, AsyncValue<Room?>, String>(
  (ref, roomId) {
    return RoomDetailsNotifier(ref.read(roomApiServiceProvider), roomId);
  },
);

class RoomDetailsNotifier extends StateNotifier<AsyncValue<Room?>> {
  final RoomApiService _api;
  final String _roomId;

  RoomDetailsNotifier(this._api, this._roomId) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final room = await _api.get(_roomId);
      state = AsyncValue.data(room);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> update(Map<String, dynamic> data) async {
    try {
      final room = await _api.update(_roomId, data);
      state = AsyncValue.data(room);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete() async {
    try {
      await _api.delete(_roomId);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String?> regenerateInviteCode() async {
    try {
      final result = await _api.regenerateInvite(_roomId);
      final newCode = result['invite_code'] as String;
      // Reload to get updated room data
      await load();
      return newCode;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

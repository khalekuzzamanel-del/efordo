import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_api_service.dart';
import '../domain/room_member.dart';

final memberProvider =
    StateNotifierProvider.family<MemberNotifier, AsyncValue<List<RoomMember>>, String>(
  (ref, roomId) {
    return MemberNotifier(ref.read(roomApiServiceProvider), roomId);
  },
);

class MemberNotifier extends StateNotifier<AsyncValue<List<RoomMember>>> {
  final RoomApiService _api;
  final String _roomId;

  MemberNotifier(this._api, this._roomId) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final members = await _api.getMembers(_roomId);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> promote(String userId) async {
    try {
      await _api.promoteMember(_roomId, userId);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> demote(String userId) async {
    try {
      await _api.demoteMember(_roomId, userId);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> remove(String userId) async {
    try {
      await _api.removeMember(_roomId, userId);
      await load();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workspace_api_service.dart';
import '../domain/workspace.dart';

final workspacesProvider =
    StateNotifierProvider<WorkspaceNotifier, AsyncValue<List<Workspace>>>((ref) {
  return WorkspaceNotifier(ref.read(workspaceApiServiceProvider));
});

class WorkspaceNotifier extends StateNotifier<AsyncValue<List<Workspace>>> {
  final WorkspaceApiService _api;

  WorkspaceNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final workspaces = await _api.list();
      state = AsyncValue.data(workspaces);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _api.create(data);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _api.update(id, data);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> archive(String id) async {
    try {
      await _api.archive(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restore(String id) async {
    try {
      await _api.restore(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

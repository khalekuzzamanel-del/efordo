import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_api_service.dart';
import '../domain/project.dart';

final projectsProvider =
    StateNotifierProvider<ProjectNotifier, AsyncValue<List<Project>>>((ref) {
  return ProjectNotifier(ref.read(projectApiServiceProvider));
});

class ProjectNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectApiService _api;
  String? _workspaceFilter;

  ProjectNotifier(this._api) : super(const AsyncValue.loading());

  String? get workspaceFilter => _workspaceFilter;

  void setWorkspaceFilter(String? workspaceId) {
    _workspaceFilter = workspaceId;
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _api.list(workspaceId: _workspaceFilter);
      state = AsyncValue.data(projects);
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

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_service.dart';
import '../domain/workspace.dart';

final workspaceApiServiceProvider = Provider<WorkspaceApiService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return WorkspaceApiService(dio.dio);
});

class WorkspaceApiService {
  final Dio _dio;

  WorkspaceApiService(this._dio);

  Future<List<Workspace>> list({bool includeArchived = false}) async {
    final response = await _dio.get('/workspaces', queryParameters: {
      if (includeArchived) 'includeArchived': 'true',
    });
    return (response.data as List).map((e) => Workspace.fromJson(e)).toList();
  }

  Future<Workspace> get(String id) async {
    final response = await _dio.get('/workspaces/$id');
    return Workspace.fromJson(response.data);
  }

  Future<Workspace> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/workspaces', data: data);
    return Workspace.fromJson(response.data);
  }

  Future<Workspace> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/workspaces/$id', data: data);
    return Workspace.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/workspaces/$id');
  }

  Future<Workspace> archive(String id) async {
    final response = await _dio.post('/workspaces/$id/archive');
    return Workspace.fromJson(response.data);
  }

  Future<Workspace> restore(String id) async {
    final response = await _dio.post('/workspaces/$id/restore');
    return Workspace.fromJson(response.data);
  }
}

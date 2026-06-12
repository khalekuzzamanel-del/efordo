import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_service.dart';
import '../domain/project.dart';

final projectApiServiceProvider = Provider<ProjectApiService>((ref) {
  final dio = ref.watch(dioServiceProvider);
  return ProjectApiService(dio.dio);
});

class ProjectApiService {
  final Dio _dio;

  ProjectApiService(this._dio);

  Future<List<Project>> list({
    String? workspaceId,
    bool includeArchived = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (workspaceId != null) queryParams['workspaceId'] = workspaceId;
    if (includeArchived) queryParams['includeArchived'] = 'true';

    final response = await _dio.get('/projects', queryParameters: queryParams);
    return (response.data as List).map((e) => Project.fromJson(e)).toList();
  }

  Future<Project> get(String id) async {
    final response = await _dio.get('/projects/$id');
    return Project.fromJson(response.data);
  }

  Future<Project> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/projects', data: data);
    return Project.fromJson(response.data);
  }

  Future<Project> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/projects/$id', data: data);
    return Project.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/projects/$id');
  }

  Future<Project> archive(String id) async {
    final response = await _dio.post('/projects/$id/archive');
    return Project.fromJson(response.data);
  }

  Future<Project> restore(String id) async {
    final response = await _dio.post('/projects/$id/restore');
    return Project.fromJson(response.data);
  }
}

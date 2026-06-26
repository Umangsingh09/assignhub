import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../models/assignment.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AssignmentRepository(dio);
});

class AssignmentRepository {
  final Dio _dio;

  AssignmentRepository(this._dio);

  Future<List<Assignment>> fetchAssignments() async {
    final response = await _dio.get('/api/assignments/');
    final list = response.data as List;
    return list.map((json) => Assignment.fromJson(json)).toList();
  }

  Future<Assignment> fetchAssignmentDetails(int id) async {
    final response = await _dio.get('/api/assignments/$id/');
    return Assignment.fromJson(response.data);
  }

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/assignments/', data: data);
    return Assignment.fromJson(response.data);
  }

  Future<Assignment> updateAssignment(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/assignments/$id/', data: data);
    return Assignment.fromJson(response.data);
  }

  Future<void> deleteAssignment(int id) async {
    await _dio.delete('/api/assignments/$id/');
  }
}

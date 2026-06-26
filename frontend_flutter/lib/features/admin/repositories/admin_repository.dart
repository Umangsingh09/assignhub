import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../models/student_profile.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminRepository(dio);
});

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<List<StudentProfile>> fetchPendingStudents() async {
    final response = await _dio.get('/api/accounts/students/pending/');
    final list = response.data as List;
    return list.map((json) => StudentProfile.fromJson(json)).toList();
  }

  Future<List<StudentProfile>> fetchAllStudents() async {
    final response = await _dio.get('/api/accounts/students/');
    final list = response.data as List;
    return list.map((json) => StudentProfile.fromJson(json)).toList();
  }

  Future<void> approveStudent(int id) async {
    await _dio.post('/api/accounts/students/$id/approve/');
  }

  Future<void> rejectStudent(int id) async {
    await _dio.post('/api/accounts/students/$id/reject/');
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../models/submission.dart';

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SubmissionRepository(dio);
});

class SubmissionRepository {
  final Dio _dio;

  SubmissionRepository(this._dio);

  Future<List<Submission>> fetchSubmissions() async {
    final response = await _dio.get('/api/submissions/');
    final list = response.data as List;
    return list.map((json) => Submission.fromJson(json)).toList();
  }

  Future<Submission> createSubmission(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/submissions/', data: data);
    return Submission.fromJson(response.data);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../models/analytics.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardAnalytics> fetchAnalytics() async {
    final response = await _dio.get('/api/dashboard/analytics/');
    return DashboardAnalytics.fromJson(response.data);
  }
}

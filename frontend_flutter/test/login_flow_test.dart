import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Real HTTP Login Request to Django', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
    try {
      final response = await dio.post('/api/accounts/login/', data: {
        'username': 'admin',
        'password': 'AdminPassword123!',
      });
      expect(response.statusCode, 200);
    } on DioException catch (e) {
      fail('DioException thrown: ${e.message}');
    } catch (e) {
      fail('Generic Exception thrown: $e');
    }
  });
}

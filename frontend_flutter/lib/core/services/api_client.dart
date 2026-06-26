import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Intercept 401 Unauthorized errors and attempt to refresh access token
        if (error.response?.statusCode == 401) {
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
              final refreshResponse = await refreshDio.post(
                '/api/accounts/token/refresh/',
                data: {'refresh': refreshToken},
              );

              if (refreshResponse.statusCode == 200) {
                final newAccessToken = refreshResponse.data['access'];
                await storage.saveTokens(access: newAccessToken);

                // Retry the original request with the new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final retryResponse = await refreshDio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                );
                return handler.resolve(retryResponse);
              }
            } catch (e) {
              // Refresh failed, trigger logout
              ref.read(authProvider.notifier).logout();
            }
          } else {
            // No refresh token available, logout
            ref.read(authProvider.notifier).logout();
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

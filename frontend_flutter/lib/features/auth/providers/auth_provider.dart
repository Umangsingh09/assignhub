import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/secure_storage.dart';

enum AuthStatus { loading, unauthenticated, pendingApproval, authenticated }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? role;
  final bool isApproved;
  final String? error;

  AuthState({
    required this.status,
    this.username,
    this.role,
    this.isApproved = false,
    this.error,
  });

  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  
  factory AuthState.unauthenticated({String? error}) => 
      AuthState(status: AuthStatus.unauthenticated, error: error);
      
  factory AuthState.pendingApproval({required String username}) => 
      AuthState(status: AuthStatus.pendingApproval, username: username);
      
  factory AuthState.authenticated({
    required String username,
    required String role,
    required bool isApproved,
  }) => AuthState(
    status: AuthStatus.authenticated,
    username: username,
    role: role,
    isApproved: isApproved,
  );
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final Dio _authDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));

  AuthNotifier(this._storage) : super(AuthState.loading()) {
    checkInitialState();
  }

  Future<void> checkInitialState() async {
    try {
      debugPrint('LOGIN_DEBUG: checkInitialState starting...');
      final token = await _storage.getAccessToken();
      final username = await _storage.getUsername();
      final role = await _storage.getUserRole();
      final approved = await _storage.isUserApproved();
      debugPrint('LOGIN_DEBUG: checkInitialState got token: ${token != null}, username: $username, role: $role, approved: $approved');

      if (token != null && username != null && role != null) {
        if (role == 'student' && !approved) {
          state = AuthState.pendingApproval(username: username);
        } else {
          state = AuthState.authenticated(
            username: username,
            role: role,
            isApproved: approved,
          );
        }
      } else {
        state = AuthState.unauthenticated();
      }
      debugPrint('LOGIN_DEBUG: checkInitialState completed, state status: ${state.status}');
    } catch (e) {
      debugPrint('LOGIN_DEBUG: checkInitialState exception: $e');
      state = AuthState.unauthenticated(error: e.toString());
    }
  }

  Future<void> login(String username, String password) async {
    debugPrint('LOGIN_DEBUG: AuthNotifier.login entered for username: $username');
    state = AuthState.loading();
    try {
      final requestUrl = '${_authDio.options.baseUrl}/api/accounts/login/';
      final requestBody = {
        'username': username,
        'password': password,
      };
      debugPrint('LOGIN_DEBUG: Dio POST request url: $requestUrl');
      debugPrint('LOGIN_DEBUG: Dio POST request headers: ${_authDio.options.headers}');
      debugPrint('LOGIN_DEBUG: Dio POST request body: ${requestBody.toString()}');
      final res = await _authDio.post('/api/accounts/login/', data: requestBody);

      debugPrint('LOGIN_DEBUG: Dio response received. Status: ${res.statusCode}');
      debugPrint('LOGIN_DEBUG: Dio response headers: ${res.headers.map}');
      debugPrint('LOGIN_DEBUG: Dio response data: ${res.data}');

      final data = res.data;
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      final role = data['role'];
      final isApproved = data['is_approved'] ?? false;

      debugPrint('LOGIN_DEBUG: Saving tokens and user role: $role, approved: $isApproved');
      await _storage.saveTokens(access: accessToken, refresh: refreshToken);
      await _storage.saveUser(username: username, role: role, isApproved: isApproved);
      debugPrint('LOGIN_DEBUG: Save completed successfully');

      if (role == 'student' && !isApproved) {
        state = AuthState.pendingApproval(username: username);
      } else {
        state = AuthState.authenticated(
          username: username,
          role: role,
          isApproved: isApproved,
        );
      }
      debugPrint('LOGIN_DEBUG: State updated to: ${state.status}');
    } on DioException catch (e) {
      debugPrint('LOGIN_DEBUG: DioException in AuthNotifier.login: $e');
      debugPrint('LOGIN_DEBUG: DioException URL: ${e.requestOptions.uri}');
      debugPrint('LOGIN_DEBUG: DioException headers: ${e.requestOptions.headers}');
      debugPrint('LOGIN_DEBUG: DioException body: ${e.requestOptions.data}');
      debugPrint('LOGIN_DEBUG: DioException response: ${e.response?.statusCode} - ${e.response?.data}');
      final errorMsg = e.response?.data?['detail'] ?? 'Login failed. Please check credentials.';
      state = AuthState.unauthenticated(error: errorMsg.toString());
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('LOGIN_DEBUG: Generic exception in AuthNotifier.login: $e');
      state = AuthState.unauthenticated(error: e.toString());
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String rollNumber,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      await _authDio.post('/api/accounts/register/', data: {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'roll_number': rollNumber,
        'password': password,
        'password2': password,
      });
      
      state = AuthState.unauthenticated();
    } on DioException catch (e) {
      final dynamic errData = e.response?.data;
      String errorMsg = 'Registration failed.';
      if (errData is Map) {
        // Collect field specific validation errors
        errorMsg = errData.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
      } else if (errData != null) {
        errorMsg = errData.toString();
      }
      state = AuthState.unauthenticated(error: errorMsg);
      throw Exception(errorMsg);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> refreshStatus() async {
    final username = await _storage.getUsername();
    final refreshToken = await _storage.getRefreshToken();
    
    if (refreshToken == null || username == null) {
      logout();
      return;
    }

    try {
      // Get new access token and inspect its payload claims for updated is_approved flag
      final res = await _authDio.post('/api/accounts/token/refresh/', data: {
        'refresh': refreshToken,
      });
      
      final access = res.data['access'];
      await _storage.saveTokens(access: access);
      
      // Decode JWT locally to check is_approved claim
      final claims = _decodeJwt(access);
      final isApproved = claims?['is_approved'] ?? false;
      final role = claims?['role'] ?? 'student';

      await _storage.saveUser(username: username, role: role, isApproved: isApproved);

      if (role == 'student' && !isApproved) {
        state = AuthState.pendingApproval(username: username);
      } else {
        state = AuthState.authenticated(
          username: username,
          role: role,
          isApproved: isApproved,
        );
      }
    } catch (e) {
      // If refresh fails, do not force log out, just leave as pending unless token is totally invalid
      if (e is DioException && e.response?.statusCode == 401) {
        logout();
      }
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = AuthState.unauthenticated();
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      // Normalize base64 URL encoding
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      return json.decode(decodedString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

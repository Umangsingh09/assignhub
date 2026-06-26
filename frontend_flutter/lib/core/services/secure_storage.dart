import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyRole = 'user_role';
  static const _keyApproved = 'user_approved';
  static const _keyUsername = 'user_username';

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _keyAccess, value: access);
    if (refresh != null) {
      await _storage.write(key: _keyRefresh, value: refresh);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccess);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefresh);
  }

  Future<void> saveUser({
    required String username,
    required String role,
    required bool isApproved,
  }) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyApproved, value: isApproved.toString());
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<bool> isUserApproved() async {
    final val = await _storage.read(key: _keyApproved);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyApproved);
    await _storage.delete(key: _keyUsername);
  }
}

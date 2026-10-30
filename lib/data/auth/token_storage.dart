import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyTokenExpiresAt = 'auth_token_expires_at';
  static const _keyAdminId = 'auth_admin_id';
  static const _keyAdminName = 'auth_admin_name';
  static const _keyAdminRole = 'auth_admin_role';
  static const _keyBaseUrl = 'auth_base_url';
  static const _keySavedUsername = 'auth_saved_username';
  static const _keyAutoReLogin = 'auth_auto_relogin';
  static const _keySavedPassword = 'auth_saved_password';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? adminId,
    String? adminName,
    String? adminRole,
    String? baseUrl,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(
        key: _keyTokenExpiresAt,
        value: expiresAt.millisecondsSinceEpoch.toString(),
      );
    }
    if (adminId != null) {
      await _storage.write(key: _keyAdminId, value: adminId);
    }
    if (adminName != null) {
      await _storage.write(key: _keyAdminName, value: adminName);
    }
    if (adminRole != null) {
      await _storage.write(key: _keyAdminRole, value: adminRole);
    }
    if (baseUrl != null) {
      await _storage.write(key: _keyBaseUrl, value: baseUrl);
    }
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<DateTime?> getTokenExpiresAt() async {
    final str = await _storage.read(key: _keyTokenExpiresAt);
    if (str == null) return null;
    final millis = int.tryParse(str);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<String?> getAdminId() => _storage.read(key: _keyAdminId);
  Future<String?> getAdminName() => _storage.read(key: _keyAdminName);
  Future<String?> getAdminRole() => _storage.read(key: _keyAdminRole);
  Future<String?> getBaseUrl() => _storage.read(key: _keyBaseUrl);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _keySavedUsername, value: username);
  Future<String?> getSavedUsername() => _storage.read(key: _keySavedUsername);
  Future<void> clearSavedUsername() => _storage.delete(key: _keySavedUsername);

  Future<void> setAutoReLogin(bool enabled, {String? password}) async {
    await _storage.write(
        key: _keyAutoReLogin, value: enabled ? 'true' : 'false');
    if (enabled && password != null) {
      await _storage.write(key: _keySavedPassword, value: password);
    } else {
      await _storage.delete(key: _keySavedPassword);
    }
  }

  Future<bool> isAutoReLoginEnabled() async {
    final val = await _storage.read(key: _keyAutoReLogin);
    return val == 'true';
  }

  Future<String?> getSavedPassword() => _storage.read(key: _keySavedPassword);

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiresAt);
    await _storage.delete(key: _keyAdminId);
    await _storage.delete(key: _keyAdminName);
    await _storage.delete(key: _keyAdminRole);
    await _storage.delete(key: _keySavedPassword);
  }
}

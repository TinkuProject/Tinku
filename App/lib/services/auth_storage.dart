import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // =========================
  // SAVE
  // =========================
  static Future<void> saveTokens(String access, String? refresh) async {
    try {
      await _storage.write(key: _accessKey, value: access);

      if (refresh != null) {
        await _storage.write(key: _refreshKey, value: refresh);
      } else {
        await _storage.delete(key: _refreshKey);
      }
    } catch (e) {
      throw Exception('Error guardando tokens');
    }
  }

  // =========================
  // LOAD
  // =========================
  static Future<Map<String, String?>> loadTokens() async {
    try {
      return {
        'accessToken': await _storage.read(key: _accessKey),
        'refreshToken': await _storage.read(key: _refreshKey),
      };
    } catch (e) {
      return {
        'accessToken': null,
        'refreshToken': null,
      };
    }
  }

  // =========================
  // CLEAR
  // =========================
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (e) {
      throw Exception('Error limpiando tokens');
    }
  }
}

// lib/core/utils/token_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // ✅ برای Web از SharedPreferences، برای موبایل از SecureStorage
  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _preferences;

  TokenManager._({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  })  : _secureStorage = secureStorage,
        _preferences = preferences;

  // ✅ Factory constructor برای ساخت مناسب بر اساس platform
  static Future<TokenManager> create() async {
    if (kIsWeb) {
      print('🌐 Initializing TokenManager for Web (SharedPreferences)');
      final prefs = await SharedPreferences.getInstance();
      return TokenManager._(preferences: prefs);
    } else {
      print('📱 Initializing TokenManager for Mobile (SecureStorage)');
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      return TokenManager._(secureStorage: storage);
    }
  }

  Future<String?> getAccessToken() async {
    try {
      if (kIsWeb) {
        return _preferences?.getString(_accessTokenKey);
      } else {
        return await _secureStorage?.read(key: _accessTokenKey);
      }
    } catch (e) {
      print('❌ Error getting access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) {
        return _preferences?.getString(_refreshTokenKey);
      } else {
        return await _secureStorage?.read(key: _refreshTokenKey);
      }
    } catch (e) {
      print('❌ Error getting refresh token: $e');
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      print('💾 Saving tokens...');
      print('🔍 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('📝 Access token length: ${accessToken.length}');
      print('📝 Refresh token length: ${refreshToken.length}');

      if (kIsWeb) {
        // ✅ Web: استفاده از SharedPreferences
        await _preferences?.setString(_accessTokenKey, accessToken);
        await _preferences?.setString(_refreshTokenKey, refreshToken);
      } else {
        // ✅ Mobile: استفاده از SecureStorage
        await _secureStorage?.write(key: _accessTokenKey, value: accessToken);
        await _secureStorage?.write(key: _refreshTokenKey, value: refreshToken);
      }

      print('✅ Tokens saved successfully');
    } catch (e, stackTrace) {
      print('❌ Error saving tokens: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> clearTokens() async {
    try {
      print('🗑️ Clearing tokens...');

      if (kIsWeb) {
        await _preferences?.remove(_accessTokenKey);
        await _preferences?.remove(_refreshTokenKey);
      } else {
        await _secureStorage?.delete(key: _accessTokenKey);
        await _secureStorage?.delete(key: _refreshTokenKey);
      }

      print('✅ Tokens cleared successfully');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

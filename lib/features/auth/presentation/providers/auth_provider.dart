import 'package:flutter/foundation.dart';
import '../../../../core/utils/token_manager.dart';
import '../../../../core/network/http_client.dart';
import '../../domain/entities/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final TokenManager tokenManager;
  final HttpClient httpClient;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get userId => _user?.id;
  AuthProvider({
    required this.tokenManager,
    required this.httpClient,
  }) {
    _checkAuthStatus();
  }

  /// بررسی وضعیت لاگین هنگام باز شدن برنامه
  Future<void> _checkAuthStatus() async {
    final token = await tokenManager.getAccessToken();
    if (token != null) {
      try {
        await _fetchCurrentUser();
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// ارسال کد تایید (OTP)
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      await httpClient.post(
        '/auth/send-otp',
        body: {'phone_number': phoneNumber},
      );

      _setStatus(AuthStatus.unauthenticated);
      return true;

    } catch (e) {
      _setError('خطا در ارسال کد. لطفاً اتصال اینترنت را بررسی کنید.');
      if (_status == AuthStatus.loading) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return false;
    }
  }

  /// بررسی کد تایید و دریافت توکن
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      print('📤 Sending OTP verification request...');

      final response = await httpClient.post(
        '/auth/verify-otp',
        body: {
          'phone_number': phoneNumber,
          'code': otp,
        },
      );

      // print('📥 Response received: $response');
      // print('🔍 Response type: ${response.runtimeType}');
      // ✅ بررسی دقیق‌تر
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected Map but got ${response.runtimeType}');
      }

      // چک access_token
      final accessToken = response['access_token'];
      if (accessToken == null) {
        print('❌ access_token is null in response');
        throw Exception('توکن در پاسخ سرور یافت نشد');
      }

      print('✅ Access token found: ${accessToken.toString().substring(0, 20)}...');

      final refreshToken = response['refresh_token'] ?? '';

      // ذخیره توکن‌ها
      print('💾 Saving tokens...');
      await tokenManager.saveTokens(
        accessToken: accessToken as String,
        refreshToken: refreshToken as String,
      );
      print('✅ Tokens saved successfully');

      // پردازش user
      if (response.containsKey('user') && response['user'] != null) {
        print('👤 Processing user data...');
        print('🔍 User data: ${response['user']}');

        try {
          _user = User.fromJson(response['user'] as Map<String, dynamic>);
          print('✅ User parsed successfully: ${_user?.phoneNumber}');
          _setStatus(AuthStatus.authenticated);
        } catch (e, st) {
          print('❌ Error parsing user: $e');
          print('📍 Stack trace: $st');
          rethrow; // این خطا رو بفرست بالا
        }

        // بعداً اطلاعات رو آپدیت کن
        _fetchCurrentUser().catchError((e) {
          print('⚠️ Could not fetch updated user: $e');
        });

        return true;
      } else {
        print('⚠️ User not in response, fetching from /users/me...');
        await _fetchCurrentUser();
        return true;
      }

    } catch (e, stackTrace) {
      print('❌ verifyOtp error: $e');
      print('📍 Full stack trace:');
      print(stackTrace);

      await tokenManager.clearTokens();

      _setError('کد وارد شده اشتباه است یا منقضی شده. جزئیات: $e');
      if (_status == AuthStatus.loading) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return false;
    }
  }


  /// دریافت اطلاعات پروفایل کاربر (Me)
  Future<void> _fetchCurrentUser() async {
    try {
      final response = await httpClient.get('/users/me');
      _user = User.fromJson(response);
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      print("❌ Error fetching user: $e");
      rethrow;
    }
  }

  /// به‌روزرسانی دستی اطلاعات کاربر
  Future<void> refreshUserData() async {
    try {
      await _fetchCurrentUser();
    } catch (e) {
      print("⚠️ Could not refresh user data: $e");
    }
  }

  Future<void> logout() async {
    await tokenManager.clearTokens();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
    notifyListeners();
  }

  // متدهای کمکی
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

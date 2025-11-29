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
        // اگر توکن داریم، اطلاعات کاربر را می‌گیریم تا مطمئن شویم توکن معتبر است
        await _fetchCurrentUser();
      } catch (e) {
        // اگر خطا داد (مثلاً توکن منقضی شده)، کاربر را لاگ‌اوت می‌کنیم
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// ارسال کد تایید (OTP)
  /// خروجی: true اگر موفق بود، false اگر خطا داد
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      // فراخوانی API بک‌اند
      await httpClient.post(
        '/auth/send-otp',
        body: {'phone_number': phoneNumber},
      );

      // نکته: اگر اینجا خطایی رخ ندهد یعنی وضعیت 200 بوده است
      // وضعیت را به unauthenticated برمی‌گردانیم تا UI فرم کد را نشان دهد (نه لودینگ)
      _setStatus(AuthStatus.unauthenticated);
      return true;

    } catch (e) {
      _setError('خطا در ارسال کد. لطفاً اتصال اینترنت را بررسی کنید.');
      // اگر هنوز روی لودینگ گیر کرده، آزادش می‌کنیم
      if (_status == AuthStatus.loading) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return false;
    }
  }

  /// بررسی کد تایید و دریافت توکن
  /// خروجی: true اگر موفق بود
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      final response = await httpClient.post(
        '/auth/verify-otp',
        body: {
          'phone_number': phoneNumber,
          'code': otp,
        },
      );

      if (response.containsKey('access_token')) {
        // ۱. ذخیره توکن‌ها
        await tokenManager.saveTokens(
          accessToken: response['access_token'],
          refreshToken: response['refresh_token'] ?? '',
        );

        // ۲. دریافت فوری اطلاعات کاربر برای تکمیل لاگین
        await _fetchCurrentUser();

        return true;
      } else {
        throw Exception('پاسخ نامعتبر از سرور');
      }

    } catch (e) {
      _setError('کد وارد شده اشتباه است یا منقضی شده.');
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
      print("Error fetching user: $e");
      throw e; // خطا را به بالا پاس می‌دهیم تا توابع فراخوان مدیریت کنند
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

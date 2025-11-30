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

      final response = await httpClient.post(
        '/auth/verify-otp',
        body: {
          'phone_number': phoneNumber,
          'code': otp,
        },
      );

      // بررسی وجود access_token
      if (!response.containsKey('access_token')) {
        throw Exception('پاسخ نامعتبر از سرور - توکن موجود نیست');
      }

      // ذخیره توکن‌ها
      await tokenManager.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'] ?? '',
      );

      // ⭐ تغییر کلیدی: ابتدا user را از response بسازیم
      if (response.containsKey('user')) {
        _user = User.fromJson(response['user']);
        _setStatus(AuthStatus.authenticated);

        // بعداً اطلاعات کاربر را به‌روز می‌کنیم (بدون اینکه لاگین به آن وابسته باشد)
        _fetchCurrentUser().catchError((e) {
          print('⚠️ Warning: Could not fetch updated user info: $e');
          // خطا را نادیده می‌گیریم چون user از response داریم
        });

        return true;
      } else {
        // اگر user در response نیست، باید حتماً fetch کنیم
        await _fetchCurrentUser();
        return true;
      }

    } catch (e) {
      print('❌ verifyOtp error: $e');

      // پاک کردن توکن‌های احتمالاً ذخیره شده
      await tokenManager.clearTokens();

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

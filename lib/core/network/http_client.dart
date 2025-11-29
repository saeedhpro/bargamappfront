import 'dart:convert';
// import 'dart:io'; // حذف شد: در وب باعث خطا می‌شود
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../error/exceptions.dart';
import '../utils/token_manager.dart';

class HttpClient {
  final String baseUrl;
  final TokenManager tokenManager;
  final http.Client client;

  HttpClient({
    required this.baseUrl,
    required this.tokenManager,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    return _makeRequest(
          () async => client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
      ),
    );
  }

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    return _makeRequest(
          () async => client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> delete(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    return _makeRequest(
          () async => client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
        body:  null,
      ),
    );
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final accessToken = await tokenManager.getAccessToken();
    if (accessToken != null) {
      defaultHeaders['Authorization'] = 'Bearer $accessToken';
    }

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return defaultHeaders;
  }

  Future<dynamic> _makeRequest(
      Future<http.Response> Function() request,
      ) async {
    try {
      var response = await request();

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await request();
        } else {
          throw AuthException('Token refresh failed');
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw NetworkException('Network error: $e');
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await tokenManager.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await tokenManager.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    switch (response.statusCode) {
      case 400: throw ValidationException('Bad request: ${response.body}');
      case 401: throw AuthException('Unauthorized');
      case 403: throw AuthException('Forbidden');
      case 404: throw ServerException('Resource not found');
      default: throw ServerException('Server error: ${response.statusCode}');
    }
  }

  // --- اصلاح شده: شامل منطق Refresh Token و سازگار با وب ---
  Future<dynamic> uploadPhoto(
      String endpoint, {
        required XFile file,
        required String fieldName,
      }) async {

    // ۱. آماده‌سازی اولیه
    final uri = Uri.parse('$baseUrl$endpoint');
    final bytes = await file.readAsBytes(); // خواندن بایت‌ها (فقط یک بار)

    // تابع کمکی برای ساخت ریکوئست (چون در صورت رفرش توکن باید دوباره ساخته شود)
    Future<http.Response> sendMultipartRequest() async {
      final request = http.MultipartRequest('POST', uri);

      // گرفتن هدر جدید (شامل توکن احتمالا جدید)
      final headers = await _buildHeaders(null);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // افزودن فایل از روی بایت‌های خوانده شده
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    try {
      // ۲. تلاش اول
      var response = await sendMultipartRequest();

      // ۳. بررسی ۴۰۱ و تلاش برای رفرش توکن
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // اگر رفرش موفق بود، دوباره ریکوئست را می‌سازیم و می‌فرستیم
          response = await sendMultipartRequest();
        } else {
          throw AuthException('Unauthorized');
        }
      }

      return _handleResponse(response);

    } catch (e) {
      if (e is AuthException) rethrow;
      throw NetworkException('Error uploading photo: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

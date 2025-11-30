import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../error/exceptions.dart';
import '../utils/token_manager.dart';

class HttpClient {
  final String baseUrl;
  final TokenManager tokenManager;
  final http.Client client;

  // تنظیمات timeout
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const Duration _uploadTimeout = Duration(seconds: 10);

  HttpClient({
    required this.baseUrl,
    required this.tokenManager,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? headers,
        Duration? timeout,
      }) async {
    return _makeRequest(
          () async => client
          .get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
      )
          .timeout(timeout ?? _defaultTimeout),
    );
  }

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        Duration? timeout,
      }) async {
    return _makeRequest(
          () async => client
          .post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(timeout ?? _defaultTimeout),
    );
  }

  Future<dynamic> delete(
      String endpoint, {
        Map<String, String>? headers,
        Duration? timeout,
      }) async {
    return _makeRequest(
          () async => client
          .delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
      )
          .timeout(timeout ?? _defaultTimeout),
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
      Future<http.Response> Function() request, {
        int retryCount = 0,
        int maxRetries = 2,
      }) async {
    try {
      var response = await request();

      // مدیریت 401 (Unauthorized)
      if (response.statusCode == 401) {
        print('🔄 Token expired, attempting refresh...');
        final refreshed = await _refreshToken();

        if (refreshed) {
          print('✅ Token refreshed successfully');
          response = await request();
        } else {
          print('❌ Token refresh failed');
          await tokenManager.clearTokens();
          throw AuthException('Authentication failed - please login again');
        }
      }

      return _handleResponse(response);

    } on TimeoutException catch (e) {
      print('⏱️ Request timeout: $e');

      // اگر هنوز retry باقی مانده، دوباره تلاش کن
      if (retryCount < maxRetries) {
        print('🔄 Retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return _makeRequest(request, retryCount: retryCount + 1, maxRetries: maxRetries);
      }

      throw NetworkException('درخواست طولانی شد. لطفاً دوباره تلاش کنید.');

    } catch (e) {
      if (e is AuthException || e is ValidationException || e is ServerException) {
        rethrow;
      }

      print('❌ Network error: $e');

      // در صورت خطای شبکه، retry کن
      if (retryCount < maxRetries) {
        print('🔄 Retrying after network error... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return _makeRequest(request, retryCount: retryCount + 1, maxRetries: maxRetries);
      }

      throw NetworkException('خطا در ارتباط با سرور: ${e.toString()}');
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await tokenManager.getRefreshToken();
      if (refreshToken == null) {
        print('⚠️ No refresh token available');
        return false;
      }

      print('📤 Sending refresh token request...');
      final response = await client
          .post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await tokenManager.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? refreshToken,
        );
        print('✅ Tokens refreshed and saved');
        return true;
      }

      print('❌ Refresh failed with status: ${response.statusCode}');
      return false;

    } catch (e) {
      print('❌ Error refreshing token: $e');
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Response decoded successfully');
        return decoded;
      } catch (e) {
        print('⚠️ Failed to decode response: $e');
        throw ServerException('Invalid response format');
      }
    }

    // مدیریت خطاها
    String errorMessage = 'Unknown error';
    try {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      errorMessage = errorBody['detail'] ?? errorBody['message'] ?? errorMessage;
    } catch (e) {
      errorMessage = response.body;
    }

    print('❌ Request failed: $errorMessage');

    switch (response.statusCode) {
      case 400:
        throw ValidationException('Bad request: $errorMessage');
      case 401:
        throw AuthException('Unauthorized: $errorMessage');
      case 403:
        throw AuthException('Forbidden: $errorMessage');
      case 404:
        throw ServerException('Resource not found: $errorMessage');
      case 500:
      case 502:
      case 503:
        throw ServerException('Server error: $errorMessage');
      default:
        throw ServerException('Error ${response.statusCode}: $errorMessage');
    }
  }

  Future<dynamic> uploadPhoto(
      String endpoint, {
        required XFile file,
        required String fieldName,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final bytes = await file.readAsBytes();

    Future<http.Response> sendMultipartRequest() async {
      final request = http.MultipartRequest('POST', uri);

      final headers = await _buildHeaders(null);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name,
      );
      request.files.add(multipartFile);

      print('📤 Uploading file: ${file.name}');
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      return await http.Response.fromStream(streamedResponse);
    }

    try {
      var response = await sendMultipartRequest();

      if (response.statusCode == 401) {
        print('🔄 Upload unauthorized, refreshing token...');
        final refreshed = await _refreshToken();
        if (refreshed) {
          response = await sendMultipartRequest();
        } else {
          throw AuthException('Unauthorized');
        }
      }

      return _handleResponse(response);

    } on TimeoutException {
      throw NetworkException('آپلود فایل طولانیفاً دوباره تلاش کنید.');
    } catch (e) {
      if (e is AuthException || e is NetworkException) rethrow;
      throw NetworkException('Error uploading photo: $e');
    }
  }

  void dispose() {
    client.close();
  }
}

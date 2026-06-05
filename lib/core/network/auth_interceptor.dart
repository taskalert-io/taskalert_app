import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Retrieve the stored access token securely
    final token = await _secureStorage.read(key: 'auth_token');

    // 2. If a token exists, inject it automatically into the authorization header
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 3. Centralized Authorization Guard: Handle expired or malicious sessions
    if (err.response?.statusCode == 401) {
      // Permanently wipe data on unauthorized response
      await _secureStorage.deleteAll();
    }
    return handler.next(err);
  }
}

import 'package:dio/dio.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import 'http_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_interceptor.dart';

class DioHttpService implements HttpService {
  late final Dio _dio;

  DioHttpService(FlutterSecureStorage secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://task-alert-backend.onrender.com/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor(secureStorage));
    // We will add global Interceptors for auth and error mapping right here next!
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  @override
  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final response = await _dio.put(path, data: body);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  @override
  Future<dynamic> patch(String path, {dynamic body}) async {
    try {
      final response = await _dio.patch(path, data: body);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  @override
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}

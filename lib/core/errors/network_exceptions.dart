import 'package:dio/dio.dart';

/// Clean user-facing error titles. Raw backend logs/strings never leak here.
enum NetworkErrorType {
  noInternet,
  serverError,
  unauthorized,
  resourceNotFound,
  timeout,
  unknown,
}

class NetworkException implements Exception {
  final NetworkErrorType errorType;
  final String userMessage;

  NetworkException({required this.errorType, required this.userMessage});

  /// Map raw Dio/Network errors immediately to safe client-side states
  factory NetworkException.fromDioError(DioException error) {
    // 1. Check if the Node.js backend sent an explicit error message string
    String? serverMessage;
    if (error.response?.data != null && error.response?.data is Map) {
      // Assuming your Node.js API sends errors as { "message": "Username already taken" }
      serverMessage = error.response?.data['message'];
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          errorType: NetworkErrorType.timeout,
          userMessage: 'Connection timed out. Please try again.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 400) {
          return NetworkException(
            errorType: NetworkErrorType.unknown,
            // 2. Use the server's exact message if present, otherwise fall back to safe text
            userMessage: serverMessage ?? 'Invalid request details provided.',
          );
        } else if (statusCode == 401 || statusCode == 403) {
          return NetworkException(
            errorType: NetworkErrorType.unauthorized,
            userMessage:
                serverMessage ?? 'Session expired. Please log in again.',
          );
        } else if (statusCode == 404) {
          return NetworkException(
            errorType: NetworkErrorType.resourceNotFound,
            userMessage:
                serverMessage ??
                'The requested information could not be found.',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            errorType: NetworkErrorType.serverError,
            userMessage:
                serverMessage ??
                'Our servers are experiencing issues. Please try later.',
          );
        }
        return NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage:
              serverMessage ?? 'Something went wrong. Please try again.',
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          errorType: NetworkErrorType.noInternet,
          userMessage: serverMessage ?? 'No internet connection detected.',
        );
      default:
        return NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: serverMessage ?? 'An unexpected error occurred.',
        );
    }
  }
}

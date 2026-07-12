import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  /// The same Dio instance every normal request goes through — needed so a
  /// request that failed with 401 can be retried with the refreshed token.
  final Dio _dio;

  AuthInterceptor(this._secureStorage, this._dio);

  /// A completely separate, interceptor-free Dio instance dedicated to the
  /// refresh-token call itself. If this went through `_dio` (and therefore
  /// back through this same interceptor), a failed refresh would recurse
  /// into `onError` again and loop forever.
  late final Dio _refreshDio = Dio(
    BaseOptions(baseUrl: _dio.options.baseUrl),
  );

  /// Coalesces concurrent 401s (e.g. several requests in flight when the
  /// token expires at once) onto a single in-flight refresh call instead of
  /// firing off a redundant refresh per request.
  Future<String?>? _refreshFuture;

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
    final isUnauthorized = err.response?.statusCode == 401;
    // Set on the retried request below — stops a token that gets rejected
    // even after a successful refresh from looping back through here again.
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried) {
      return handler.next(err);
    }

    final newToken = await _refreshAccessToken();

    if (newToken == null) {
      // Refresh token missing, expired, or the refresh call itself failed —
      // there's no way to recover this session silently. Same fallback as
      // before: wipe it so the user lands back on sign-in.
      await _secureStorage.deleteAll();
      return handler.next(err);
    }

    // Replay the original request with the fresh token, transparently to
    // whoever made the call — they just see it succeed.
    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newToken';
      retryOptions.extra = {...retryOptions.extra, 'retried': true};

      final response = await _dio.fetch(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    // Already refreshing (from a concurrent 401) — piggyback on that
    // instead of starting a second refresh call.
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    final future = _doRefresh();
    _refreshFuture = future;
    future.whenComplete(() => _refreshFuture = null);
    return future;
  }

  Future<String?> _doRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await _refreshDio.post(
        '/auth/access-token',
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final newAccessToken = data is Map ? data['accessToken'] : null;
      if (newAccessToken == null) return null;

      final tokenString = newAccessToken.toString();
      await _secureStorage.write(key: 'auth_token', value: tokenString);
      return tokenString;
    } catch (_) {
      return null;
    }
  }
}

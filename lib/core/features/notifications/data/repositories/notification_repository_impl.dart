import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final HttpService _httpService;

  NotificationRepositoryImpl(this._httpService);

  /// 1. GET: Fetch all notifications for the authenticated user
  @override
  Future<ApiResult<BaseApiResponse<List<NotificationModel>>>>
  getNotifications({int? page}) async {
    try {
      final responseData = page != null
          ? await _httpService.get(
              '/notifications',
              queryParams: {'page': page},
            )
          : await _httpService.get('/notifications');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      NotificationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <NotificationModel>[];
        },
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 2. PUT: Mark every notification as read
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> markAllRead() async {
    try {
      final responseData = await _httpService.put(
        '/notifications/mark-all-read',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 3. PUT: Mark a single notification as read
  @override
  Future<ApiResult<BaseApiResponse<NotificationModel>>> markRead({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/notifications/$id/mark-read',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }
}

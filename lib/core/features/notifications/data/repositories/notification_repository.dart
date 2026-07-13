import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<ApiResult<BaseApiResponse<List<NotificationModel>>>>
  getNotifications({int? page});

  Future<ApiResult<BaseApiResponse<dynamic>>> markAllRead();

  Future<ApiResult<BaseApiResponse<NotificationModel>>> markRead({
    required String id,
  });
}

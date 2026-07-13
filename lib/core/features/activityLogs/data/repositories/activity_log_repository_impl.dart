import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/activity_log_model.dart';
import 'activity_log_repository.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final HttpService _httpService;

  ActivityLogRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<BaseApiResponse<ActivityLogResponse>>>
  getInstanceActivityLogs({required String instanceId}) async {
    try {
      // Adjusted path as needed based on endpoint standards
      final responseData = await _httpService.get(
        '/activity-logs/instance/$instanceId',
      );
      final responseMap = responseData as Map<String, dynamic>;

      final apiResponse = BaseApiResponse.fromJson(responseMap, (dataJson) {
        // Pass both the 'data' layer list and the root payload mapping to extract everything together
        return ActivityLogResponse.fromJson(dataJson, responseMap);
      });

      if (apiResponse.success) return ApiResult.success(apiResponse);
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

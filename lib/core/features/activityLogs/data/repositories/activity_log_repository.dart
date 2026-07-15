import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/activity_log_model.dart';

abstract class ActivityLogRepository {
  /// Fetches context activity trails with absolute type isolation for compound fields
  Future<ApiResult<BaseApiResponse<ActivityLogResponse>>>
  getInstanceActivityLogs({required String instanceId});
}

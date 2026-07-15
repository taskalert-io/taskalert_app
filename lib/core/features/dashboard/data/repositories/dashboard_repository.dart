import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/dashboard_task_model.dart';

abstract class DashboardRepository {
  /// GET /tasks/all-tasks — organization-wide task list for the logged-in
  /// user (paginated).
  Future<ApiResult<BaseApiResponse<List<DashboardTaskModel>>>> getAllTasks({
    String? assigned,
    String? organization,
    bool? expand,
    int? page,
    int? limit,
  });
}

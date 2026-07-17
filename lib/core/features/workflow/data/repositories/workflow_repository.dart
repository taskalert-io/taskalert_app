import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/workflow_model.dart';

abstract class WorkflowRepository {
  /// 1. GET /workflow — paginated list of workflow instances for the
  /// logged-in user.
  Future<ApiResult<BaseApiResponse<List<WorkflowModel>>>> getAllWorkflows({
    int? page,
    int? limit,
  });

  /// 2. GET /workflow/:workflowId — full workflow detail + subtask timeline.
  /// The path id is a TaskInstance id (`WorkflowModel.instanceId` from the
  /// list endpoint) — not the workflow list item's own `_id`.
  Future<ApiResult<BaseApiResponse<WorkflowDetailResponse>>> getWorkflowById({
    required String taskInstanceId,
  });
}

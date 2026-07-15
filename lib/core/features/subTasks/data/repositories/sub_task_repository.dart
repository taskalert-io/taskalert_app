import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/sub_task_model.dart';

abstract class SubTaskRepository {
  // ── SubTask (template, scoped to a task instance) ─────────────────────────

  /// 1. POST /tasks/instances/:instanceId/subtasks
  Future<ApiResult<BaseApiResponse<SubTaskModel>>> createSubTask({
    required String instanceId,
    required String title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? scope,
  });

  // ── SubTask Instance (generated occurrence of a SubTask) ──────────────────

  /// 7. GET /tasks/instances/:instanceId/subtask-instances
  Future<ApiResult<BaseApiResponse<List<SubTaskModel>>>>
  getAllSubTaskInstances({required String instanceId});

  /// 8. GET /tasks/subtask-instances/:subTaskInstanceId
  Future<ApiResult<BaseApiResponse<SubTaskModel>>> getSubTaskInstanceById({
    required String subTaskInstanceId,
  });

  /// 9. PUT /tasks/subtasks/instance/update/:subTaskInstanceId — quick
  /// status/assignee/priority patch
  Future<ApiResult<BaseApiResponse<dynamic>>>
  updateSubTaskInstanceStatusAssigneePriority({
    required String subTaskInstanceId,
    String? status,
    List<String>? assigneeIds,
    String? priority,
  });

  /// 10. PUT /tasks/subtasks/instance/:subTaskInstanceId — full update
  Future<ApiResult<BaseApiResponse<SubTaskModel>>> updateSubTaskInstance({
    required String subTaskInstanceId,
    String? title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? status,
    String? scope,
  });

  /// 11. DELETE /tasks/subtasks/instance/:subTaskInstanceId
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteSubTaskInstance({
    required String subTaskInstanceId,
  });
}

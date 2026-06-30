import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/task_instance_model.dart';

abstract class TaskInstanceRepository {
  Future<ApiResult<BaseApiResponse<List<TaskInstanceModel>>>> getAllInstances();

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>> getInstanceById({
    required String instanceId,
  });

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceConfiguration({
    required String taskId,
    required String instanceId,
    required String status,
    required String priority,
    required List<String> assigneeIds,
    required Map<String, String>
    scheduledTime, // e.g., {"time": "12:00", "period": "PM"}
    required String scope,
  });

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceStatusPriorityAssignees({
    required String instanceId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
  });
}

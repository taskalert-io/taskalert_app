import 'dart:io';

import 'package:taskalert_app/core/features/taskInstance/data/models/task_instances_response.dart';

import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/task_instance_model.dart';

abstract class TaskInstanceRepository {
  Future<ApiResult<BaseApiResponse<TaskInstancesResponse>>> getAllInstances({
    String? date,
    String? startDate,
    String? endDate,
    bool? expand,
    String? assigned,
    String? status,
    String? sortBy,
    String? order,
  });
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>> getInstanceById({
    required String instanceId,
  });

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceConfiguration({
    required String taskId,
    required String instanceId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
    Map<String, String>? scheduledTime,
    String? scope,
  });

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceStatusPriorityAssignees({
    required String taskId,
    required String instanceId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
  });

  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  uploadInstanceProofFiles({
    required String taskId,
    required String instanceId,
    required List<File> proofFiles,
  });
}

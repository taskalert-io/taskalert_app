import 'dart:io';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/task_model.dart';

abstract class TaskRepository {
  Future<ApiResult<BaseApiResponse<TaskModel>>> getSingleTask({
    required String taskId,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> updateTaskStatus({
    required String taskId,
    required String status,
  });

  Future<ApiResult<BaseApiResponse<TaskModel>>> updateTask({
    required String taskId,
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  });

  Future<ApiResult<BaseApiResponse<List<TaskModel>>>> getAllTasks({
    String? taskType,
    String? status,
    String? department,
    String? assigned
  });

  Future<ApiResult<BaseApiResponse<TaskModel>>> createTask({
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  });
}

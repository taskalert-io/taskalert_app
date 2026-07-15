import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import 'sub_task_repository.dart';
import '../models/sub_task_instance_model.dart';
import '../models/sub_task_model.dart';

class SubTaskRepositoryImpl implements SubTaskRepository {
  final HttpService _httpService;

  SubTaskRepositoryImpl(this._httpService);

  /// 1. POST: Create a SubTask under a task instance
  @override
  Future<ApiResult<BaseApiResponse<SubTaskCreateResponse>>> createSubTask({
    required String instanceId,
    required String title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? scope,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/tasks/instances/$instanceId/subtasks',
        body: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (assigneeIds != null) 'assignees': assigneeIds,
          if (time != null && period != null)
            'reportingTime': {'time': time, 'period': period},
          if (scope != null && scope.isNotEmpty) 'scope': scope,
        },
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) =>
            SubTaskCreateResponse.fromJson(json as Map<String, dynamic>),
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
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 7. GET: Fetch all SubTask Instances for a task instance
  @override
  Future<ApiResult<BaseApiResponse<SubTaskInstancesResponse>>>
  getAllSubTaskInstances({required String instanceId}) async {
    try {
      final responseData = await _httpService.get(
        '/tasks/instances/$instanceId/subtask-instances',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) =>
            SubTaskInstancesResponse.fromJson(dataJson as Map<String, dynamic>),
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

  /// 8. GET: Fetch a single SubTask Instance by id
  @override
  Future<ApiResult<BaseApiResponse<SubTaskInstanceModel>>>
  getSubTaskInstanceById({required String subTaskInstanceId}) async {
    try {
      final responseData = await _httpService.get(
        '/tasks/subtask-instances/$subTaskInstanceId',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => SubTaskInstanceModel.fromJson(json as Map<String, dynamic>),
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

  /// 9. PUT: Quick status/assignee/priority patch for a SubTask Instance
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>>
  updateSubTaskInstanceStatusAssigneePriority({
    required String subTaskInstanceId,
    String? status,
    List<String>? assigneeIds,
    String? priority,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/tasks/subtasks/instance/update/$subTaskInstanceId',
        body: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (assigneeIds != null) 'assignees': assigneeIds,
          if (priority != null && priority.isNotEmpty) 'priority': priority,
        },
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

  /// 10. PUT: Full update of a SubTask Instance
  @override
  Future<ApiResult<BaseApiResponse<SubTaskInstanceModel>>>
  updateSubTaskInstance({
    required String subTaskInstanceId,
    String? title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? status,
    String? scope,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/tasks/subtasks/instance/$subTaskInstanceId',
        body: {
          if (title != null && title.isNotEmpty) 'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (assigneeIds != null) 'assignees': assigneeIds,
          if (time != null && period != null)
            'reportingTime': {'time': time, 'period': period},
          if (status != null && status.isNotEmpty) 'status': status,
          if (scope != null && scope.isNotEmpty) 'scope': scope,
        },
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => SubTaskInstanceModel.fromJson(json as Map<String, dynamic>),
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

  /// 11. DELETE: Delete a SubTask Instance
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteSubTaskInstance({
    required String subTaskInstanceId,
  }) async {
    try {
      final responseData = await _httpService.delete(
        '/tasks/subtasks/instance/$subTaskInstanceId',
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
}

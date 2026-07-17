import 'dart:io';

import 'package:dio/dio.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instances_response.dart';

import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/task_instance_model.dart';
import 'task_instance_repository.dart';

class TaskInstanceRepositoryImpl implements TaskInstanceRepository {
  final HttpService _httpService;

  TaskInstanceRepositoryImpl(this._httpService);

  /// 1. GET: Fetch all task instances for the logged-in user
  @override
  Future<ApiResult<BaseApiResponse<TaskInstancesResponse>>> getAllInstances({
    String? date,
    String? startDate,
    String? endDate,
    bool? expand,
    String? assigned,
    String? status,
    String? sortBy,
    String? order,
    bool? overdue,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (date != null) queryParameters['date'] = date;
      if (startDate != null) queryParameters['startDate'] = startDate;
      if (endDate != null) queryParameters['endDate'] = endDate;
      if (expand != null) queryParameters['expand'] = expand;
      if (assigned != null) queryParameters['assigned'] = assigned;
      if (status != null) queryParameters['status'] = status;
      if (sortBy != null) queryParameters['sortBy'] = sortBy;
      if (order != null) queryParameters['order'] = order;
      if (overdue != null) queryParameters['overdue'] = overdue;

      final responseData = await _httpService.get(
        '/tasks/instances',
        queryParams: queryParameters,
      );
      final responseMap = responseData as Map<String, dynamic>;

      final apiResponse = BaseApiResponse.fromJson(responseMap, (json) {
        // Force the factory mapping parser to evaluate the root layout directly
        return TaskInstancesResponse.fromJson(responseMap, responseMap);
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
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a field the backend
      // returns differently than expected) so a parsing bug surfaces as a
      // normal failure instead of an uncaught exception that leaves the
      // caller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 2. GET: Fetch specific task instance metrics details
  @override
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>> getInstanceById({
    required String instanceId,
  }) async {
    try {
      final responseData = await _httpService.get(
        '/tasks/instances/$instanceId',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskInstanceModel.fromJson(json as Map<String, dynamic>),
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
      // Guards against unexpected response shapes (e.g. a field the backend
      // returns differently than expected) so a parsing bug surfaces as a
      // normal failure instead of an uncaught exception that leaves the
      // caller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 3. PUT: Full Configuration Instance Update (Requires Task ID & Instance ID)
  @override
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceConfiguration({
    required String taskId,
    required String instanceId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
    // String? scheduledDate,
    Map<String, String>? scheduledTime,
    String? scope,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "status": status,
        "priority": priority,
        "assignees": assigneeIds,
        // "scheduledDate": scheduledDate,
        "scheduledTime": scheduledTime,
        "scope": scope,
      };

      final responseData = await _httpService.put(
        '/tasks/$taskId/instances/$instanceId',
        body: body,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskInstanceModel.fromJson(json as Map<String, dynamic>),
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
      // Guards against unexpected response shapes (e.g. a field the backend
      // returns differently than expected) so a parsing bug surfaces as a
      // normal failure instead of an uncaught exception that leaves the
      // caller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 4. PUT: Partial metadata patch updates for standalone instances
  @override
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  updateInstanceStatusPriorityAssignees({
    required String instanceId,
    required String taskId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (status != null && status.isNotEmpty) body['status'] = status;
      if (priority != null && priority.isNotEmpty) body['priority'] = priority;
      if (assigneeIds != null) body['assignees'] = assigneeIds;

      final responseData = await _httpService.put(
        '/tasks/instance/update/$instanceId',
        body: body,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskInstanceModel.fromJson(json as Map<String, dynamic>),
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
      // Guards against unexpected response shapes (e.g. a field the backend
      // returns differently than expected) so a parsing bug surfaces as a
      // normal failure instead of an uncaught exception that leaves the
      // caller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 5. PUT: Upload Proof Files for an Instance (multipart Form-Data)
  @override
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  uploadInstanceProofFiles({
    required String taskId,
    required String instanceId,
    required List<File> proofFiles,
  }) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var file in proofFiles) {
        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }

      final formData = FormData.fromMap({'proofFiles': multipartFiles});

      final responseData = await _httpService.put(
        '/tasks/$taskId/instances/$instanceId/proof',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskInstanceModel.fromJson(json as Map<String, dynamic>),
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
      // Guards against unexpected response shapes (e.g. a field the backend
      // returns differently than expected) so a parsing bug surfaces as a
      // normal failure instead of an uncaught exception that leaves the
      // caller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 6. DELETE: Remove one or more already-uploaded proof files from an
  /// instance, identified by their cloud storage `publicId`s.
  @override
  Future<ApiResult<BaseApiResponse<TaskInstanceModel>>>
  deleteInstanceProofFile({
    required String taskId,
    required String instanceId,
    required List<String> publicIds,
  }) async {
    try {
      final responseData = await _httpService.delete(
        '/tasks/$taskId/instances/$instanceId/proof',
        body: {'publicId': publicIds},
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskInstanceModel.fromJson(json as Map<String, dynamic>),
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

  /// 7. DELETE: Delete a task instance ("single" or "following" scope)
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteInstance({
    required String taskId,
    required String instanceId,
    required String scope,
  }) async {
    try {
      final responseData = await _httpService.delete(
        '/tasks/$taskId/instances/$instanceId',
        body: {'scope': scope},
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

import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import 'task_repository.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final HttpService _httpService;

  TaskRepositoryImpl(this._httpService);

  /// 1. GET: Fetch Single Task
  @override
  Future<ApiResult<BaseApiResponse<TaskModel>>> getSingleTask({
    required String taskId,
  }) async {
    try {
      final responseData = await _httpService.get('/tasks/$taskId');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskModel.fromJson(json as Map<String, dynamic>),
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
    }
  }

  /// 2. PUT: Update Task Status
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/tasks/update/$taskId',
        body: {'status': status},
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
    }
  }

  /// 3. PUT: Update Task (with multipart Form-Data)
  @override
  Future<ApiResult<BaseApiResponse<TaskModel>>> updateTask({
    required String taskId,
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  }) async {
    try {
      final Map<String, dynamic> map = Map.from(bodyFields);

      if (files != null && files.isNotEmpty) {
        List<MultipartFile> multipartFiles = [];
        for (var file in files) {
          multipartFiles.add(
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          );
        }
        map['attachments'] = multipartFiles;
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.put(
        '/tasks/$taskId',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskModel.fromJson(json as Map<String, dynamic>),
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
    }
  }

  /// 4. GET: Get All Tasks (with optional filters)
  @override
  Future<ApiResult<BaseApiResponse<List<TaskModel>>>> getAllTasks({
    String? taskType,
    String? status,
    String? department,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (taskType != null) queryParameters['taskType'] = taskType;
      if (status != null) queryParameters['status'] = status;
      if (department != null) queryParameters['department'] = department;

      final responseData = await _httpService.get(
        '/tasks',
        queryParams: queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <TaskModel>[];
        },
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
    }
  }

  /// 5. POST: Create Task (with multipart Form-Data attachments)
  @override
  Future<ApiResult<BaseApiResponse<TaskModel>>> createTask({
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  }) async {
    try {
      final Map<String, dynamic> map = Map.from(bodyFields);

      if (files != null && files.isNotEmpty) {
        List<MultipartFile> multipartFiles = [];
        for (var file in files) {
          multipartFiles.add(
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          );
        }
        map['attachments'] = multipartFiles;
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.post('/tasks', body: formData);

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => TaskModel.fromJson(json as Map<String, dynamic>),
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
    }
  }
}

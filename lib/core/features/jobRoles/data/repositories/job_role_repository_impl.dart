import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/job_role_model.dart';
import 'job_role_repository.dart';

class JobRoleRepositoryImpl implements JobRoleRepository {
  final HttpService _httpService;

  JobRoleRepositoryImpl(this._httpService);

  /// 1. GET: Fetch all job roles
  @override
  Future<ApiResult<BaseApiResponse<List<JobRoleModel>>>> getJobRoles() async {
    try {
      final responseData = await _httpService.get('/job-roles');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) => JobRoleModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <JobRoleModel>[];
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

  /// 2. POST: Create a new job role
  @override
  Future<ApiResult<BaseApiResponse<JobRoleModel>>> createJobRole({
    required String title,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/job-roles',
        body: {'title': title},
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => JobRoleModel.fromJson(json as Map<String, dynamic>),
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

  /// 3. GET: Fetch a single job role by id
  @override
  Future<ApiResult<BaseApiResponse<JobRoleModel>>> getJobRoleById({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.get('/job-roles/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => JobRoleModel.fromJson(json as Map<String, dynamic>),
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

  /// 4. PUT: Update a job role
  @override
  Future<ApiResult<BaseApiResponse<JobRoleModel>>> updateJobRole({
    required String id,
    required String title,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/job-roles/$id',
        body: {'title': title},
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => JobRoleModel.fromJson(json as Map<String, dynamic>),
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

  /// 5. DELETE: Delete a job role
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteJobRole({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.delete('/job-roles/$id');

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

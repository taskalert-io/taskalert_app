import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import 'workflow_repository.dart';
import '../models/workflow_model.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final HttpService _httpService;

  WorkflowRepositoryImpl(this._httpService);

  /// 1. GET: Fetch all workflows for the logged-in user (paginated)
  @override
  Future<ApiResult<BaseApiResponse<List<WorkflowModel>>>> getAllWorkflows({
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (page != null) queryParameters['page'] = page;
      if (limit != null) queryParameters['limit'] = limit;

      final responseData = await _httpService.get(
        '/workflow',
        queryParams: queryParameters.isEmpty ? null : queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) => WorkflowModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <WorkflowModel>[];
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

  /// 2. GET: Fetch full workflow detail + subtask timeline. The path id is
  /// a TaskInstance id, not the workflow list item's own `_id`.
  @override
  Future<ApiResult<BaseApiResponse<WorkflowDetailResponse>>> getWorkflowById({
    required String taskInstanceId,
  }) async {
    try {
      final responseData = await _httpService.get(
        '/workflow/$taskInstanceId',
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) =>
            WorkflowDetailResponse.fromJson(dataJson as Map<String, dynamic>),
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

import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import 'dashboard_repository.dart';
import '../models/dashboard_task_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final HttpService _httpService;

  DashboardRepositoryImpl(this._httpService);

  /// GET: Fetch the organization-wide task list for the logged-in user
  @override
  Future<ApiResult<BaseApiResponse<List<DashboardTaskModel>>>> getAllTasks({
    String? assigned,
    String? organization,
    bool? expand,
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (assigned != null) queryParameters['assigned'] = assigned;
      if (organization != null) queryParameters['organization'] = organization;
      if (expand != null) queryParameters['expand'] = expand;
      if (page != null) queryParameters['page'] = page;
      if (limit != null) queryParameters['limit'] = limit;

      final responseData = await _httpService.get(
        '/tasks/all-tasks',
        queryParams: queryParameters.isEmpty ? null : queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      DashboardTaskModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <DashboardTaskModel>[];
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
}

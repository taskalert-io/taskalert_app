import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/sidebar_config_model.dart';
import 'sidebar_repository.dart';

class SidebarRepositoryImpl implements SidebarRepository {
  final HttpService _httpService;

  SidebarRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<BaseApiResponse<SidebarConfigModel>>>
  getSidebarConfiguration() async {
    try {
      // GET request to {{baseURL}}/sidebar/me
      final responseData = await _httpService.get('/sidebar/me');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => SidebarConfigModel.fromJson(json as Map<String, dynamic>),
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

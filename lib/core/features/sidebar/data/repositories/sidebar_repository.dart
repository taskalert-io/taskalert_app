import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/sidebar_config_model.dart';

abstract class SidebarRepository {
  /// Fetches navigation visibility hierarchy mapped to current user permissions
  Future<ApiResult<BaseApiResponse<SidebarConfigModel>>>
  getSidebarConfiguration();
}

import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/organization_model.dart';

abstract class OrganizationRepository {
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
    required String name,
    required String email,
    required String phoneNumber,
    String? street,
    String? city,
    String? state,
    String? country,
    String? pinCode,
    String? imageFilePath, // Path to local file if picked from gallery/camera
  });

  Future<ApiResult<BaseApiResponse<List<OrganizationModel>>>>
  getOrganizations();

  Future<ApiResult<BaseApiResponse<OrganizationModel>>> getOrganizationById({
    required String id,
  });

  Future<ApiResult<BaseApiResponse<OrganizationModel>>> updateOrganization({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    String? street,
    String? city,
    String? state,
    String? country,
    String? pinCode,
    String? imageFilePath,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> deleteOrganization({
    required String id,
  });

  /// GET /organizations/me — the organization currently scoped to the
  /// logged-in user's session (their active organization).
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> getMyOrganization();

  /// POST /auth/switch-organization — changes which organization the
  /// user's session is scoped to. Response is parsed the same way as
  /// sign-in/sign-up (it may or may not include fresh tokens, depending on
  /// whether the backend scopes the JWT to the active organization).
  Future<ApiResult<BaseApiResponse<UserModel>>> switchOrganization({
    required String organizationId,
  });
}

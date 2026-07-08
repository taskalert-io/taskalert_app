import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../data/models/organization_model.dart';

abstract class OrganizationRepository {
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
    required String name,
    required String email,
    required String phoneNumber,
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
    String? imageFilePath,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> deleteOrganization({
    required String id,
  });
}

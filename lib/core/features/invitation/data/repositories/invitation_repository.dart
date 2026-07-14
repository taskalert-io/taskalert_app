import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/invitation_model.dart';

abstract class InvitationRepository {
  /// Sends a new invitation to an email address.
  Future<ApiResult<BaseApiResponse<Invitation>>> createInvitation({
    required String firstName,
    required String lastName,
    required String email,
    required String organizationId,
  });

  /// Fetches invitations filtered optionally by a search string.
  Future<ApiResult<BaseApiResponse<List<Invitation>>>> getInvitations({
    String? search,
  });

  /// Revokes an invitation using its unique resource ID.
  Future<ApiResult<BaseApiResponse<dynamic>>> revokeInvitation({
    required String invitationId,
  });

  /// Validates an invitation token from an incoming link.
  Future<ApiResult<BaseApiResponse<dynamic>>> validateToken({
    required String token,
  });
}

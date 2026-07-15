import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import '../models/invitation_model.dart';
import 'invitation_repository.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final HttpService _httpService;

  InvitationRepositoryImpl(this._httpService);

  /// 1. POST: Send a new invitation to an email address
  @override
  Future<ApiResult<BaseApiResponse<Invitation>>> createInvitation({
    required String firstName,
    required String lastName,
    required String email,
    required String organizationId,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/invitations/',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'organizationId': organizationId,
        },
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => Invitation.fromJson(json as Map<String, dynamic>),
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

  /// 2. GET: Fetch invitations, optionally filtered by a search string
  @override
  Future<ApiResult<BaseApiResponse<List<Invitation>>>> getInvitations({
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final responseData = await _httpService.get(
        '/invitations/',
        queryParams: queryParameters.isEmpty ? null : queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      Invitation.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <Invitation>[];
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

  /// 3. DELETE: Revoke an existing invitation
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> revokeInvitation({
    required String invitationId,
  }) async {
    try {
      final responseData = await _httpService.delete(
        '/invitations/$invitationId',
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

  /// 4. GET: Validate an invitation token from an incoming link
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> validateToken({
    required String token,
  }) async {
    try {
      final responseData = await _httpService.get(
        '/invitations/validate',
        queryParams: {'token': token},
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
}

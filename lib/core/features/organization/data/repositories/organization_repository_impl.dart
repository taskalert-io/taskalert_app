import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/organization_model.dart';
import 'organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final HttpService _httpService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  OrganizationRepositoryImpl(this._httpService);

  /// 1. POST: Create Organization (with optional multi-part logo image file)
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
    required String name,
    required String email,
    required String phoneNumber,
    String? imageFilePath,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      };

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final String fileName = imageFilePath.split('/').last;
        map['image'] = await MultipartFile.fromFile(
          imageFilePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.post(
        '/organizations',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _secureStorage.write(
          key: 'user_requires_organization',
          value: 'false',
        );
        return ApiResult.success(apiResponse);
      }

      // if (apiResponse.success) return ApiResult.success(apiResponse);
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

  /// 2. GET: Fetch all organizations
  @override
  Future<ApiResult<BaseApiResponse<List<OrganizationModel>>>>
  getOrganizations() async {
    try {
      final responseData = await _httpService.get('/organizations');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      OrganizationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <OrganizationModel>[];
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

  /// 3. GET: Fetch single organization metadata details by ID
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> getOrganizationById({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.get('/organizations/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
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

  /// 4. PUT: Update organization data fields and optional image payload
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> updateOrganization({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    String? imageFilePath,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      };

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final String fileName = imageFilePath.split('/').last;
        map['image'] = await MultipartFile.fromFile(
          imageFilePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.put(
        '/organizations/$id',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
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

  /// 5. DELETE: Permanently drop an organization profile
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteOrganization({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.delete('/organizations/$id');

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

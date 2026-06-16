import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskalert_app/core/features/auth/data/models/profile_model.dart';
import 'auth_repository.dart';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import '../../../../errors/network_exceptions.dart';
import '../../data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final HttpService _httpService;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._httpService, this._secureStorage);

  /// Helper utility to dynamically resolve and throw clean validation errors
  void _handleErrorEnvelope(BaseApiResponse response) {
    String errorMessage = response.message;
    if (response.validationErrors != null &&
        response.validationErrors!.isNotEmpty) {
      errorMessage = response.validationErrors!.values.first.toString();
    }
    throw NetworkException(
      errorType: NetworkErrorType.unknown,
      userMessage: errorMessage,
    );
  }

  // =========================================================================
  // SIGN UP FLOW
  // =========================================================================

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> signUp({
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/signup',
        body: {'phoneNumber': phoneNumber, 'email': email},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<UserModel>>> verifySignUpOtp({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required String otpCode,
    String? email,
    String? gender,
    String? dateOfBirth,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/verify-signup-otp',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'password': password,
          'agreeTerms': agreeTerms,
          'otpCode': otpCode,
          if (email != null) 'email': email,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        },
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => UserModel.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final user = apiResponse.data!;

        if (user.token != null) {
          await _secureStorage.write(key: 'auth_token', value: user.token!);
          await _secureStorage.write(
            key: 'refresh_token',
            value: user.refreshToken ?? '',
          );

          await _secureStorage.write(key: 'user_id', value: user.id);
          await _secureStorage.write(key: 'user_email', value: user.email);
          await _secureStorage.write(
            key: 'user_phone',
            value: user.phoneNumber,
          );
          await _secureStorage.write(
            key: 'user_first_name',
            value: user.firstName,
          );
          await _secureStorage.write(
            key: 'user_last_name',
            value: user.lastName,
          );
          await _secureStorage.write(
            key: 'user_avatar_original',
            value: user.originalAvatarUrl ?? '',
          );
          await _secureStorage.write(
            key: 'user_avatar_thumbnail',
            value: user.thumbnailAvatarUrl ?? '',
          );
        }
        return ApiResult.success(apiResponse);
      }

      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignUpOtp({
    required String phoneNumber,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/resend-signup-otp',
        body: {'phoneNumber': phoneNumber},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      _handleErrorEnvelope(apiResponse);
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

  // =========================================================================
  // SIGN IN FLOW
  // =========================================================================

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> signIn({
    required String phoneNumber, // Mapping phone to email for passwordless flow
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/signin',
        body: {'phoneNumber': phoneNumber},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<UserModel>>> verifySignInOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/verify-signin-otp',
        body: {'phoneNumber': phoneNumber, 'otpCode': otpCode},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => UserModel.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final user = apiResponse.data!;
        // NOTE: Securely storing accessToken upon verification sequence success
        if (user.token != null) {
          await _secureStorage.write(key: 'auth_token', value: user.token!);
          await _secureStorage.write(
            key: 'refresh_token',
            value: user.refreshToken ?? '',
          );

          await _secureStorage.write(key: 'user_id', value: user.id);
          await _secureStorage.write(key: 'user_email', value: user.email);
          await _secureStorage.write(
            key: 'user_phone',
            value: user.phoneNumber,
          );
          await _secureStorage.write(
            key: 'user_first_name',
            value: user.firstName,
          );
          await _secureStorage.write(
            key: 'user_last_name',
            value: user.lastName,
          );
          await _secureStorage.write(
            key: 'user_avatar_original',
            value: user.originalAvatarUrl ?? '',
          );
          await _secureStorage.write(
            key: 'user_avatar_thumbnail',
            value: user.thumbnailAvatarUrl ?? '',
          );
        }
        return ApiResult.success(apiResponse);
      }
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignInOtp({
    required String phoneNumber,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/resend-signin-otp',
        body: {'phoneNumber': phoneNumber},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      _handleErrorEnvelope(apiResponse);
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

  // =========================================================================
  // ROOT-LEVEL & PROFILE MANAGEMENT
  // =========================================================================

  @override
  Future<ApiResult<String>> refreshToken({
    required String currentRefreshToken,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/refresh-token',
        body: {'refreshToken': currentRefreshToken},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success &&
          apiResponse.data != null &&
          apiResponse.data?['accessToken'] != null) {
        final newAccessToken = apiResponse.data?['accessToken'].toString();
        await _secureStorage.write(key: 'auth_token', value: newAccessToken);
        return ApiResult.success(newAccessToken!);
      }
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<ProfileModel>>> getProfile() async {
    try {
      final responseData = await _httpService.get('/auth/profile');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => ProfileModel.fromJson(json as Map<String, dynamic>),
      );

      // if (apiResponse.success) {
      //   // return ApiResult.success(apiResponse);
      // }

      if (apiResponse.success && apiResponse.data != null) {
        final user = apiResponse.data!;

        // 🌟 Safe persistence check using the explicit profile userId property mapping
        if (user.userId.isNotEmpty) {
          // Note: If your /auth/profile endpoint provides token variants, extract them from user properties here.
          // Assuming token tracking might belong to login models, but keeping your storage keys matching perfectly:

          await _secureStorage.write(key: 'user_id', value: user.userId);
          await _secureStorage.write(key: 'user_email', value: user.email);
          await _secureStorage.write(
            key: 'user_phone',
            value: user.phoneNumber,
          );
          await _secureStorage.write(
            key: 'user_first_name',
            value: user.firstName,
          );
          await _secureStorage.write(
            key: 'user_last_name',
            value: user.lastName,
          );

          await _secureStorage.write(
            key: 'user_dob',
            value: user.dateOfBirth.toString(),
          );

          await _secureStorage.write(
            key: 'user_job',
            value: user.jobRole?.title,
          );
          await _secureStorage.write(
            key: 'user_department',
            value: user.department?.name,
          );

          // 🌟 Safely accessing nested Cloudinary profile image trees
          await _secureStorage.write(
            key: 'user_avatar_original',
            value: user.image?.originalUrl ?? '',
          );
          await _secureStorage.write(
            key: 'user_avatar_thumbnail',
            value: user.image?.thumbnailUrl ?? '',
          );
        }

        return ApiResult.success(apiResponse);
      }

      _handleErrorEnvelope(apiResponse);
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

  // @override
  // Future<ApiResult<BaseApiResponse<dynamic>>> getProfile() async {
  //   try {
  //     final responseData = await _httpService.get('/auth/profile');

  //     final apiResponse = BaseApiResponse.fromJson(
  //       responseData,
  //       (json) => UserModel.fromJson(json),
  //     );

  //     if (apiResponse.success && apiResponse.data != null) {
  //       return ApiResult.success(apiResponse.data! as BaseApiResponse<dynamic>);
  //     }
  //     _handleErrorEnvelope(apiResponse);
  //     return ApiResult.failure(
  //       NetworkException(
  //         errorType: NetworkErrorType.unknown,
  //         userMessage: apiResponse.message,
  //       ),
  //     );
  //   } on NetworkException catch (e) {
  //     return ApiResult.failure(e);
  //   }
  // }

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    File? avatarFile,
  }) async {
    try {
      // Use Multi-part construction for form-data support
      final Map<String, dynamic> formMap = {
        'firstName': firstName,
        'lastName': lastName,
      };

      if (avatarFile != null) {
        formMap['avatar'] = await dio.MultipartFile.fromFile(
          avatarFile.path,
          filename: avatarFile.path.split('/').last,
        );
      }

      final formData = dio.FormData.fromMap(formMap);
      final responseData = await _httpService.post(
        '/auth/profile/update',
        body: formData,
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => UserModel.fromJson(json),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return ApiResult.success(apiResponse.data! as BaseApiResponse<dynamic>);
      }
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/auth/profile/password',
        body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => json,
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);
      _handleErrorEnvelope(apiResponse);
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

  @override
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}

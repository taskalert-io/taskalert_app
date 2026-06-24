import 'dart:io';
// import 'package:taskalert_app/core/features/auth/data/models/user_model.dart';

import 'package:taskalert_app/core/features/auth/data/models/user_model.dart';

import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// import '../../core/network/otp_response_model.dart'; // Assuming your inner payload maps here
// import '../../core/network/user_model.dart'; // Assuming your inner user structure maps here

abstract class AuthRepository {
  // --- Sign Up Flow ---
  Future<ApiResult<BaseApiResponse<dynamic>>> signUp({
    required String phoneNumber,
    String? email,
  });

  Future<ApiResult<BaseApiResponse<UserModel>>> verifySignUpOtp({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required String otpCode,
    required String accountType,
    String? email,
    String? gender,
    String? dateOfBirth,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignUpOtp({
    required String phoneNumber,
  });

  // --- Sign In Flow ---
  Future<ApiResult<BaseApiResponse<dynamic>>> signIn({
    // required String email,
    // required String password,
    required String phoneNumber, // Mapping phone to email for passwordless flow
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> verifySignInOtp({
    required String phoneNumber, // Mapping phone to email for passwordless flow
    required String otpCode,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignInOtp({
    required String phoneNumber, // Mapping phone to email for passwordless flow
  });

  // --- Session Management ---
  Future<ApiResult<String>> refreshToken({required String currentRefreshToken});

  Future<void> logout();

  // --- Profile Management ---
  Future<ApiResult<BaseApiResponse<dynamic>>> getProfile();

  Future<ApiResult<BaseApiResponse<dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    File? avatarFile,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> updatePassword({
    required String oldPassword,
    required String newPassword,
  });
}

import 'dart:io';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// import '../../core/network/otp_response_model.dart'; // Assuming your inner payload maps here
// import '../../core/network/user_model.dart'; // Assuming your inner user structure maps here

abstract class AuthRepository {
  // --- Sign Up Flow ---
  Future<ApiResult<BaseApiResponse<dynamic>>> signUp({
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<ApiResult<UserModel>> verifySignUpOtp({
    required String email,
    required String otp,
    required String firstName,
    required String lastName,
    String? referralCode,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignUpOtp({
    required String email,
  });

  // --- Sign In Flow ---
  Future<ApiResult<BaseApiResponse<dynamic>>> signIn({
    // required String email,
    // required String password,
    required String phoneNumber, // Mapping phone to email for passwordless flow
  });

  Future<ApiResult<UserModel>> verifySignInOtp({
    required String email,
    required String otp,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> resendSignInOtp({
    required String email,
  });

  // --- Session Management ---
  Future<ApiResult<String>> refreshToken({required String currentRefreshToken});

  Future<void> logout();

  // --- Profile Management ---
  Future<ApiResult<UserModel>> getProfile();

  Future<ApiResult<UserModel>> updateProfile({
    required String firstName,
    required String lastName,
    File? avatarFile,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> updatePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String?
  token; // This captures the accessToken returned on verification responses

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Handles both traditional SQL 'id' and MongoDB '_id' systems automatically
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      avatarUrl:
          json['avatarUrl'] ??
          json['avatar'], // Catches variations in profile image field naming
      token:
          json['accessToken'] ??
          json['token'], // Maps 'accessToken' post-response dynamically
    );
  }
}

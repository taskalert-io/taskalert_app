import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:taskalert_app/core/features/auth/data/models/profile_model.dart';
import 'package:taskalert_app/core/features/auth/data/models/user_model.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import '../data/repositories/auth_repository.dart';
import 'package:taskalert_app/core/network/api_result.dart';

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginController(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _currentPhoneNumber;
  String? get currentPhoneNumber => _currentPhoneNumber;

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  // ✅ Dev/test backends echo the generated OTP back in the response so the
  // UI can auto-fill it instead of requiring the user to check SMS/email.
  String? _otp;
  String? get otp => _otp;

  /// Calls the repository and returns true if the OTP was successfully dispatched
  Future<bool> handlePhoneSignIn({required String phoneNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _otp = null;
    notifyListeners();

    try {
      // 1. Fire the request through our decoupled repository contract
      // Note: We use a placeholder string for password since your UI screenshot is currently passwordless
      final result = await _authRepository.signIn(
        phoneNumber: phoneNumber, // Mapping phone to the unique credential field
      );

      // 2. Unpack the clean functional pattern result
      if (result is Success) {
        _currentPhoneNumber = phoneNumber; // Cache the identifier locally
        final apiResponse = (result as Success).data;
        // Only surface the dev/test backend's echoed OTP in debug builds — a
        // release build must never read or display this, regardless of what
        // the backend returns.
        _otp = kDebugMode ? apiResponse.data['otp']?.toString() : null;
        _successMessage = _otp != null
            ? '${apiResponse.message} Your OTP is: $_otp'
            : apiResponse.message ?? 'OTP sent successfully to $phoneNumber';
        return true; // Tells the UI it's safe to push the OTP verification screen
      } else if (result is Failure) {
        // Automatically captures our clean, obfuscated or backend validation message
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> handleVerifyOtp({required String otp}) async {
    if (_currentPhoneNumber == null) {
      _errorMessage = "Session expired. Please enter your phone number again.";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Fire the repository method
      final result = await _authRepository.verifySignInOtp(
        phoneNumber: _currentPhoneNumber!,
        otpCode: otp,
      );

      // 2. Unpack the clean functional pattern result safely
      if (result is Success) {
        // result.data gives you what AuthRepositoryImpl returned: a parsed UserModel object!
        final apiResponse =
            (result as Success).data as BaseApiResponse<UserModel>;

        // Second, extract the clean nested UserModel payload from inside it
        final user = apiResponse.data;
        return user;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return null;
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleResendOtp() async {
    if (_currentPhoneNumber == null) return false;

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.resendSignInOtp(
        phoneNumber: _currentPhoneNumber!,
      );

      if (result is Success) {
        final apiResponse = (result as Success).data;
        // _successMessage = apiResponse.message;
        _otp = kDebugMode ? apiResponse.data['otp']?.toString() : null;
        if (_otp != null) {
          _successMessage = " Your new OTP is: $_otp";
        } else {
          _successMessage = " OTP resent successfully to ${_currentPhoneNumber!}";
        }

        return true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleLogout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();

      _currentPhoneNumber = null;
      _successMessage = null;
      _errorMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleGetProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.getProfile();
      bool isSuccess = false;

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<ProfileModel>;

        _profile = apiResponse.data;
        _successMessage = apiResponse.message;
        isSuccess = true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        isSuccess = false;
      }

      return isSuccess;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleUpdateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? email,
    String? jobRole,
    String? language,
    String? languageCode,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        jobRole: jobRole,
        language: language,
        languageCode: languageCode,
        imageFile: imageFile,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        return true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleUpdatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        return true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleRequestAccountDeletion() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.requestAccountDeletion();

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        return true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Coordinates registering a company structure profile right after user registration succeeds
  Future<bool> handleRegisterOrganizationProfile({
    required String email,
    required String name,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.registerOrganizationProfile(
        email: email,
        name: name,
        phoneNumber: phoneNumber,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        return true;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return false;
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

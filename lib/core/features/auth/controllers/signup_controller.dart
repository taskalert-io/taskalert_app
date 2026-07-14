import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:taskalert_app/core/features/auth/data/models/user_model.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import '../data/repositories/auth_repository.dart';
import 'package:taskalert_app/core/network/api_result.dart';

class SignUpController extends ChangeNotifier {
  final AuthRepository _authRepository;

  SignUpController(this._authRepository);

  // States
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // Cache phone number for OTP and Resend actions
  String? _currentPhoneNumber;
  String? get currentPhoneNumber => _currentPhoneNumber;

  // ✅ Dev/test backends echo the generated OTP back in the response so the
  // UI can auto-fill it instead of requiring the user to check SMS/email.
  String? _otp;
  String? get otp => _otp;

  /// Utility to seed or transfer phone number across fields
  void setPhoneNumber(String phoneNumber) {
    _currentPhoneNumber = phoneNumber;
    notifyListeners();
  }

  /// 1. Initial Step: Request Sign-Up OTP
  Future<bool> handleSignUp({
    required String phoneNumber,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _otp = null;
    notifyListeners();

    try {
      final result = await _authRepository.signUp(
        phoneNumber: phoneNumber,
        email: email,
      );

      if (result is Success) {
        _currentPhoneNumber = phoneNumber;
        final apiResponse = (result as Success).data;
        // Only surface the dev/test backend's echoed OTP in debug builds — a
        // release build must never read or display this, regardless of what
        // the backend returns.
        _otp = kDebugMode ? apiResponse.data['otp']?.toString() : null;
        _successMessage = _otp != null
            ? '${apiResponse.message} Your OTP is: $_otp'
            : apiResponse.message;
        // Cache phone number for subsequent steps

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

  /// 2. Verification Step: Validate User Profile Details + OTP Code
  Future<UserModel?> handleVerifySignUpOtp({
    required String firstName,
    required String lastName,
    required String password,
    required bool agreeTerms,
    required String otpCode,
    required String accountType,

    String? email,
    String? gender,
    String? dateOfBirth,
  }) async {
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
      final result = await _authRepository.verifySignUpOtp(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: _currentPhoneNumber!,
        password: password,
        agreeTerms: agreeTerms,
        otpCode: otpCode,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        accountType: accountType,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<UserModel>;
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

  /// 3. Auxiliary Step: Resend Sign-Up OTP Code
  Future<bool> handleResendSignUpOtp() async {
    if (_currentPhoneNumber == null) {
      _errorMessage = "Session expired. Please restart the sign up process.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.resendSignUpOtp(
        phoneNumber: _currentPhoneNumber!,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
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
}

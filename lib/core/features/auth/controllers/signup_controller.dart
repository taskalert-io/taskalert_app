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
    notifyListeners();

    final result = await _authRepository.signUp(
      phoneNumber: phoneNumber,
      email: email,
    );

    _isLoading = false;

    if (result is Success) {
      _currentPhoneNumber = phoneNumber;
      final apiResponse = (result as Success).data;
      // _successMessage = apiResponse.message;
      _successMessage = apiResponse.message + apiResponse.data['otp'];
      // Cache phone number for subsequent steps

      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }

    return false;
  }

  /// 2. Verification Step: Validate User Profile Details + OTP Code
  Future<UserModel?> handleVerifySignUpOtp({
    required String firstName,
    required String lastName,
    required String password,
    required bool agreeTerms,
    required String otpCode,
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
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<UserModel>;
      final user = apiResponse.data;

      notifyListeners();

      return user;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return null;
    }

    return null;
  }

  /// 3. Auxiliary Step: Resend Sign-Up OTP Code
  Future<bool> handleResendSignUpOtp() async {
    print("Attempting to resend Sign-Up OTP for phone: $_currentPhoneNumber");
    if (_currentPhoneNumber == null) {
      _errorMessage = "Session expired. Please restart the sign up process.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _authRepository.resendSignUpOtp(
      phoneNumber: _currentPhoneNumber!,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      final otp = apiResponse.data['otp'];
      if (otp != null) {
        _successMessage = " Your new OTP is: $otp";
      } else {
        _successMessage = " OTP resent successfully to ${_currentPhoneNumber!}";
      }
      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }

    return false;
  }
}

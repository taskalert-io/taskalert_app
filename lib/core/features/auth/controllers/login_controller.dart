import 'package:flutter/material.dart';
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

  /// Calls the repository and returns true if the OTP was successfully dispatched
  Future<bool> handlePhoneSignIn({required String phoneNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // 1. Fire the request through our decoupled repository contract
    // Note: We use a placeholder string for password since your UI screenshot is currently passwordless
    final result = await _authRepository.signIn(
      phoneNumber: phoneNumber, // Mapping phone to the unique credential field
    );

    _isLoading = false;

    // 2. Unpack the clean functional pattern result
    if (result is Success) {
      _currentPhoneNumber = phoneNumber; // Cache the identifier locally
      final apiResponse = (result as Success).data;
      _successMessage =
          apiResponse.message + apiResponse.data['otp'] ??
          'OTP sent successfully to $phoneNumber';
      notifyListeners();
      return true; // Tells the UI it's safe to push the OTP verification screen
    } else if (result is Failure) {
      // Automatically captures our clean, obfuscated or backend validation message
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }

    return false;
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

    // 1. Fire the repository method
    final result = await _authRepository.verifySignInOtp(
      phoneNumber: _currentPhoneNumber!,
      otpCode: otp,
    );

    _isLoading = false;

    // 2. Unpack the clean functional pattern result safely
    if (result is Success) {
      print("OTP verification successful, unpacking user data...{$result}");
      // result.data gives you what AuthRepositoryImpl returned: a parsed UserModel object!
      final apiResponse =
          (result as Success).data as BaseApiResponse<UserModel>;

      // Second, extract the clean nested UserModel payload from inside it
      final user = apiResponse.data;
      print("$user");
      notifyListeners();
      return user;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return null;
    }
    return null;
  }

  // Future<UserModel?> handleVerifyOtp({required String otp}) async {
  //   if (_currentPhoneNumber == null) {
  //     _errorMessage = "Session expired. Please enter your phone number again.";
  //     notifyListeners();
  //     return null;
  //   }

  //   _isLoading = true;
  //   _errorMessage = null;
  //   _successMessage = null;
  //   notifyListeners();

  //   // Map your verification logic here using the stored phone context
  //   final result = await _authRepository.verifySignInOtp(
  //     phoneNumber: _currentPhoneNumber!,
  //     otpCode: otp,
  //   );

  //   _isLoading = false;

  //   if (result is Success) {
  //     final user = (result) as UserModel;
  //     notifyListeners();
  //     return user; // Return the user object so the UI can greet them or redirect to home
  //   } else if (result is Failure) {
  //     _errorMessage = (result as Failure).exception.userMessage;
  //     notifyListeners();
  //     return null;
  //   }
  //   return null;
  // }

  Future<bool> handleResendOtp() async {
    if (_currentPhoneNumber == null) return false;

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _authRepository.resendSignInOtp(
      phoneNumber: _currentPhoneNumber!,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data;
      _successMessage = apiResponse.message;
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

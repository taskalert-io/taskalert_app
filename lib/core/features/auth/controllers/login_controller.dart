import 'package:flutter/material.dart';
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
}

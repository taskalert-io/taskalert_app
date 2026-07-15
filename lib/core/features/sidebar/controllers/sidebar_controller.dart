import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import '../data/models/sidebar_config_model.dart';
import '../data/repositories/sidebar_repository.dart';

class SidebarController extends ChangeNotifier {
  final SidebarRepository _repository;

  SidebarController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SidebarConfigModel? _config;
  SidebarConfigModel? get config => _config;

  void clearMessages() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetches which drawer/sidebar items the logged-in user has access to.
  Future<void> handleGetSidebarConfiguration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getSidebarConfiguration();

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<SidebarConfigModel>;
        _config = apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

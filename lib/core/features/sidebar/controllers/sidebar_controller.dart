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
  ///
  /// This controller is registered as an app-wide singleton (not a fresh
  /// instance per screen), so [_config] persists across every screen's own
  /// `CustomDrawer` — by default this only actually calls the API once per
  /// session and every later call (e.g. a new screen's drawer mounting)
  /// just reuses the cached result. Pass [forceRefresh] when the
  /// permission set could genuinely have changed (organization switch).
  Future<void> handleGetSidebarConfiguration({bool forceRefresh = false}) async {
    if (!forceRefresh && _config != null) return;

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

  /// Clears the cached config — call on logout so a different user signing
  /// in on the same app session doesn't briefly see the previous user's
  /// sidebar before their own fetch resolves.
  void reset() {
    _config = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

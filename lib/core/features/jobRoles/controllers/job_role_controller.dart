import 'package:flutter/material.dart';
import '../../../network/api_result.dart';
import '../../../network/base_api_response.dart';
import '../data/models/job_role_model.dart';
import '../data/repositories/job_role_repository.dart';

class JobRoleController extends ChangeNotifier {
  final JobRoleRepository _repository;

  JobRoleController(this._repository);

  // --- State Variables ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<JobRoleModel> _jobRoles = [];
  List<JobRoleModel> get jobRoles => _jobRoles;

  // --- Helper Methods ---
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // --- API Handlers ---

  /// 1. Fetch All Job Roles
  Future<void> handleGetJobRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getJobRoles();
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<JobRoleModel>>;
      _jobRoles = apiResponse.data ?? [];
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Create a Job Role
  Future<bool> handleCreateJobRole({required String title}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.createJobRole(title: title);

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<JobRoleModel>;
      _successMessage = apiResponse.message;

      // Opt-in optimization: add newly created item directly to local list state
      if (apiResponse.data != null) {
        _jobRoles.insert(0, apiResponse.data!);
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

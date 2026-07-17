import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../data/models/dashboard_task_model.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<DashboardTaskModel> _tasks = [];
  List<DashboardTaskModel> get tasks => _tasks;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Fetch the organization-wide task list for the logged-in user
  Future<void> handleGetAllTasks({
    String? assigned,
    String? organization,
    bool? expand,
    int? page,
    int? limit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllTasks(
        assigned: assigned,
        organization: organization,
        expand: expand,
        page: page,
        limit: limit,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data
                as BaseApiResponse<List<DashboardTaskModel>>;
        _tasks = apiResponse.data ?? [];
        _pagination = apiResponse.pagination;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

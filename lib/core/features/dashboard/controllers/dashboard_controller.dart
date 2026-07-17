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

  // Per-organization fetch failures from the most recent
  // `handleGetAllTasksForOrganizations` call, keyed by organization id —
  // lets callers tell "this organization genuinely has zero tasks" apart
  // from "this organization's request failed", which a single merged
  // `_tasks` list can't distinguish on its own.
  Map<String, String> _orgErrors = {};
  Map<String, String> get orgErrors => _orgErrors;

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

  /// Fetches and merges tasks across every given organization. Unlike
  /// [handleGetAllTasks] with no `organization` filter — which, in
  /// practice, only ever returns the currently *active* organization's
  /// tasks — this hits the endpoint once per organization id (in
  /// parallel) so the Dashboard screen can show every organization the
  /// user belongs to, not just the active one.
  Future<void> handleGetAllTasksForOrganizations(
    List<String> organizationIds, {
    String? assigned,
    bool? expand,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _orgErrors = {};
    notifyListeners();

    try {
      final results = await Future.wait(
        organizationIds.map(
          (orgId) => _repository.getAllTasks(
            assigned: assigned,
            organization: orgId,
            expand: expand,
          ),
        ),
      );

      final merged = <DashboardTaskModel>[];
      final errors = <String, String>{};
      for (var i = 0; i < organizationIds.length; i++) {
        final result = results[i];
        if (result is Success) {
          final apiResponse =
              (result as Success).data
                  as BaseApiResponse<List<DashboardTaskModel>>;
          merged.addAll(apiResponse.data ?? []);
        } else if (result is Failure) {
          errors[organizationIds[i]] =
              (result as Failure).exception.userMessage;
        }
      }

      _tasks = merged;
      _pagination = null;
      _orgErrors = errors;
      if (errors.isNotEmpty) {
        _errorMessage =
            'Could not load tasks for ${errors.length} organization(s).';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

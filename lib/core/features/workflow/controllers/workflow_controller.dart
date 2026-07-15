import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../data/models/workflow_model.dart';
import '../data/repositories/workflow_repository.dart';

class WorkflowController extends ChangeNotifier {
  final WorkflowRepository _repository;

  WorkflowController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<WorkflowModel> _workflows = [];
  List<WorkflowModel> get workflows => _workflows;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  WorkflowDetailResponse? _selectedWorkflow;
  WorkflowDetailResponse? get selectedWorkflow => _selectedWorkflow;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch all workflows for the logged-in user (paginated)
  Future<void> handleGetAllWorkflows({int? page, int? limit}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllWorkflows(
        page: page,
        limit: limit,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<List<WorkflowModel>>;
        _workflows = apiResponse.data ?? [];
        _pagination = apiResponse.pagination;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. Fetch full workflow detail + subtask timeline. [taskInstanceId] is
  /// `WorkflowModel.instanceId` from the list endpoint, not the list
  /// item's own `_id`.
  Future<void> handleGetWorkflowById({required String taskInstanceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getWorkflowById(
        taskInstanceId: taskInstanceId,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data
                as BaseApiResponse<WorkflowDetailResponse>;
        _selectedWorkflow = apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import '../data/models/sub_task_model.dart';
import '../data/repositories/sub_task_repository.dart';

class SubTaskController extends ChangeNotifier {
  final SubTaskRepository _repository;

  SubTaskController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  final List<SubTaskModel> _subTasks = [];
  List<SubTaskModel> get subTasks => _subTasks;

  List<SubTaskModel> _subTaskInstances = [];
  List<SubTaskModel> get subTaskInstances => _subTaskInstances;

  SubTaskModel? _selectedSubTaskInstance;
  SubTaskModel? get selectedSubTaskInstance => _selectedSubTaskInstance;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── SubTask (template) ─────────────────────────────────────────────────────

  /// 1. Create a SubTask under a task instance
  Future<bool> handleCreateSubTask({
    required String instanceId,
    required String title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? scope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.createSubTask(
        instanceId: instanceId,
        title: title,
        description: description,
        assigneeIds: assigneeIds,
        time: time,
        period: period,
        scope: scope,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<SubTaskModel>;
        _successMessage = apiResponse.message;
        if (apiResponse.data != null) {
          _subTasks.insert(0, apiResponse.data!);
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

  // ── SubTask Instance ────────────────────────────────────────────────────────

  /// 7. Fetch all SubTask Instances for a task instance
  Future<void> handleGetAllSubTaskInstances({
    required String instanceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAllSubTaskInstances(
        instanceId: instanceId,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<List<SubTaskModel>>;
        _subTaskInstances = apiResponse.data ?? [];
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 8. Fetch a single SubTask Instance by id
  Future<void> handleGetSubTaskInstanceById({
    required String subTaskInstanceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getSubTaskInstanceById(
        subTaskInstanceId: subTaskInstanceId,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<SubTaskModel>;
        _selectedSubTaskInstance = apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 9. Quick status/assignee/priority patch for a SubTask Instance
  Future<bool> handleUpdateSubTaskInstanceStatusAssigneePriority({
    required String subTaskInstanceId,
    String? status,
    List<String>? assigneeIds,
    String? priority,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository
          .updateSubTaskInstanceStatusAssigneePriority(
            subTaskInstanceId: subTaskInstanceId,
            status: status,
            assigneeIds: assigneeIds,
            priority: priority,
          );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
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

  /// 10. Full update of a SubTask Instance
  Future<bool> handleUpdateSubTaskInstance({
    required String subTaskInstanceId,
    String? title,
    String? description,
    List<String>? assigneeIds,
    String? time,
    String? period,
    String? status,
    String? scope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.updateSubTaskInstance(
        subTaskInstanceId: subTaskInstanceId,
        title: title,
        description: description,
        assigneeIds: assigneeIds,
        time: time,
        period: period,
        status: status,
        scope: scope,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<SubTaskModel>;
        _successMessage = apiResponse.message;

        if (apiResponse.data != null) {
          final index = _subTaskInstances.indexWhere(
            (s) => s.id == subTaskInstanceId,
          );
          if (index != -1) _subTaskInstances[index] = apiResponse.data!;
          if (_selectedSubTaskInstance?.id == subTaskInstanceId) {
            _selectedSubTaskInstance = apiResponse.data;
          }
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

  /// 11. Delete a SubTask Instance
  Future<bool> handleDeleteSubTaskInstance({
    required String subTaskInstanceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _repository.deleteSubTaskInstance(
        subTaskInstanceId: subTaskInstanceId,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        _subTaskInstances.removeWhere((s) => s.id == subTaskInstanceId);
        if (_selectedSubTaskInstance?.id == subTaskInstanceId) {
          _selectedSubTaskInstance = null;
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

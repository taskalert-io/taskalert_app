import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../data/repositories/task_repository.dart';
import '../data/models/task_model.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskController(this._taskRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  TaskModel? _selectedTask;
  TaskModel? get selectedTask => _selectedTask;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch All Tasks (with optional query filters)
  Future<void> handleGetAllTasks({
    String? taskType,
    String? status,
    String? department,
    String? assigned,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskRepository.getAllTasks(
        taskType: taskType,
        status: status,
        department: department,
        assigned: assigned,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<List<TaskModel>>;
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

  /// 2. Fetch Single Task Details exclusively via Object ID Link
  Future<void> handleGetSingleTask({required String taskId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _taskRepository.getSingleTask(taskId: taskId);

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<TaskModel>;
        _selectedTask = apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Create Task (Optimistically prepends new task item to array)
  Future<bool> handleCreateTask({
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _taskRepository.createTask(
        bodyFields: bodyFields,
        files: files,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<TaskModel>;
        _successMessage = apiResponse.message;

        if (apiResponse.data != null) {
          _tasks.insert(0, apiResponse.data!);
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

  /// 4. Full Task Update (Replaces changed element within current UI view layout)
  Future<bool> handleUpdateTask({
    required String taskId,
    required Map<String, dynamic> bodyFields,
    List<File>? files,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _taskRepository.updateTask(
        taskId: taskId,
        bodyFields: bodyFields,
        files: files,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<TaskModel>;
        _successMessage = apiResponse.message;

        final index = _tasks.indexWhere((element) => element.id == taskId);
        if (index != -1 && apiResponse.data != null) {
          _tasks[index] = apiResponse.data!;
        }

        if (_selectedTask?.id == taskId && apiResponse.data != null) {
          _selectedTask = apiResponse.data;
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

  /// 5. Update Task Status (Modifies target task status dynamically)
  Future<bool> handleUpdateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _taskRepository.updateTaskStatus(
        taskId: taskId,
        status: status,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;

        // Update the status locally in the list representation without re-fetching
        final index = _tasks.indexWhere((element) => element.id == taskId);
        if (index != -1) {
          // Creates a cloned version updating just the status parameter
          _tasks[index] = _updateLocalStatus(_tasks[index], status);
        }

        if (_selectedTask?.id == taskId && _selectedTask != null) {
          _selectedTask = _updateLocalStatus(_selectedTask!, status);
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

  /// Helper utility logic to safely assign status modifications locally
  TaskModel _updateLocalStatus(TaskModel model, String newStatus) {
    return TaskModel(
      id: model.id,
      taskType: model.taskType,
      taskId: model.taskId,
      isSubTask: model.isSubTask,
      parentTask: model.parentTask,
      title: model.title,
      department: model.department, // Passes down the DepartmentModel?
      priority: model.priority,
      assignees: model.assignees, // Passes down the List<ReportingUserModel>
      reportingDate: model.reportingDate,
      reportingTime: model.reportingTime,
      description: model.description,
      attachments: model.attachments,
      organization: model.organization,
      createdBy: model.createdBy,
      completionStatus: newStatus, // Target updated field 🌟
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      reportingTo: model.reportingTo,

      // 🌟 Updated: Pass the clean nested sub-models we created
      recurrence: model.recurrence,
      proofConfig: model.proofConfig,
    );
  }

  // /// Helper utility logic to safely assign status modifications locally
  // TaskModel _updateLocalStatus(TaskModel model, String newStatus) {
  //   return TaskModel(
  //     id: model.id,
  //     taskType: model.taskType,
  //     taskId: model.taskId,
  //     isSubTask: model.isSubTask,
  //     parentTask: model.parentTask,
  //     title: model.title,
  //     department: model.department,
  //     priority: model.priority,
  //     assignees: model.assignees,
  //     reportingDate: model.reportingDate,
  //     reportingTime: model.reportingTime,
  //     description: model.description,
  //     attachments: model.attachments,
  //     organization: model.organization,
  //     createdBy: model.createdBy,
  //     completionStatus: newStatus, // Target updated field 🌟
  //     createdAt: model.createdAt,
  //     updatedAt: model.updatedAt,
  //     reportingTo: model.reportingTo,
  //     timePeriod: model.timePeriod,
  //     everyN: model.everyN,
  //     daysOfWeek: model.daysOfWeek,
  //     monthlyType: model.monthlyType,
  //     dayOfMonth: model.dayOfMonth,
  //     weekOfMonth: model.weekOfMonth,
  //     dayOfWeekMonthly: model.dayOfWeekMonthly,
  //     rangeStart: model.rangeStart,
  //     endType: model.endType,
  //     endByDate: model.endByDate,
  //     endAfterCount: model.endAfterCount,
  //     proofTypes: model.proofTypes,
  //     aiValidationEnabled: model.aiValidationEnabled,
  //   );
  // }
}

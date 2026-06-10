import 'dart:io';
import 'package:flutter/material.dart';
import '../data/repositories/task_repository.dart';
import '../data/models/task_model.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskController(this._taskRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TaskModel> _tasksList = [];
  List<TaskModel> get tasksList => _tasksList;

  TaskModel? _selectedTask;
  TaskModel? get selectedTask => _selectedTask;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 1. Get Single Task
  Future<void> handleGetSingleTask(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taskRepository.getSingleTask(taskId: taskId);

    result.when(
      success: (response) {
        _selectedTask = response.data;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// 2. Update Status Only
  Future<bool> handleUpdateTaskStatus(String taskId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taskRepository.updateTaskStatus(
      taskId: taskId,
      status: status,
    );
    bool isSuccess = false;

    result.when(
      success: (response) {
        isSuccess = response.success;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
    return isSuccess;
  }

  /// 3. Full Task Update
  Future<bool> handleUpdateTask(
    String taskId,
    Map<String, dynamic> bodyFields,
    List<File>? files,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taskRepository.updateTask(
      taskId: taskId,
      bodyFields: bodyFields,
      files: files,
    );
    bool isSuccess = false;

    result.when(
      success: (response) {
        isSuccess = response.success;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
    return isSuccess;
  }

  /// 4. Get All Tasks
  Future<void> handleGetAllTasks({
    String? taskType,
    String? status,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taskRepository.getAllTasks(
      taskType: taskType,
      status: status,
      department: department,
    );

    result.when(
      success: (response) {
        _tasksList = response.data;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// 5. Create New Task
  Future<bool> handleCreateTask(
    Map<String, dynamic> bodyFields,
    List<File>? files,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taskRepository.createTask(
      bodyFields: bodyFields,
      files: files,
    );
    bool isSuccess = false;

    result.when(
      success: (response) {
        isSuccess = response.success;
      },
      failure: (exception) {
        _errorMessage = exception.userMessage;
      },
    );

    _isLoading = false;
    notifyListeners();
    return isSuccess;
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instance_counts_model.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instances_response.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../data/models/task_instance_model.dart';
import '../data/repositories/task_instance_repository.dart';

class TaskInstanceController extends ChangeNotifier {
  final TaskInstanceRepository _repository;

  TaskInstanceController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<TaskInstanceModel> _instances = [];
  List<TaskInstanceModel> get instances => _instances;

  TaskInstanceModel? _selectedInstance;
  TaskInstanceModel? get selectedInstance => _selectedInstance;

  TaskInstanceCountsModel? _instanceCounts;
  TaskInstanceCountsModel? get instanceCounts => _instanceCounts;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch All Instances
  Future<void> handleGetAllInstances({
    String? date,
    String? startDate,
    String? endDate,
    bool? expand,
    String? assigned,
    String? status,
    String? sortBy,
    String? order,
    bool? overdue,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getAllInstances(
      date: date,
      startDate: startDate,
      endDate: endDate,
      expand: expand,
      assigned: assigned,
      status: status,
      sortBy: sortBy,
      order: order,
      overdue: overdue,
    );
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstancesResponse>;

      // Clean, type-safe assignment extracted directly from our custom wrapper
      _instances = apiResponse.data?.instances ?? [];

      _instanceCounts = apiResponse.data?.counts;
      _pagination = apiResponse.pagination;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Fetch Instance Details
  Future<void> handleGetInstanceById({required String instanceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getInstanceById(instanceId: instanceId);
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstanceModel>;
      _selectedInstance = apiResponse.data;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 3. Update Full Configuration Instance
  Future<bool> handleUpdateInstanceConfiguration({
    required String taskId,
    required String instanceId,
    required String status,
    String? priority,
    List<String>? assigneeIds,
    String? date,
    String? time,
    String? period,
    required String scope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.updateInstanceConfiguration(
      taskId: taskId,
      instanceId: instanceId,
      status: status,
      priority: priority,
      assigneeIds: assigneeIds,
      // scheduledDate: date,
      scheduledTime: {"time": ?time, "period": ?period},
      scope: scope,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstanceModel>;
      _successMessage = apiResponse.message;

      // Sync data inside local state tracking collections
      final index = _instances.indexWhere(
        (element) => element.id == instanceId,
      );
      if (index != -1 && apiResponse.data != null) {
        _instances[index] = apiResponse.data!;
      }
      if (_selectedInstance?.id == instanceId) {
        _selectedInstance = apiResponse.data;
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

  /// 4. Partial Updates for Status, Priority, and Assignees
  Future<bool> handleUpdateInstanceStatusPriorityAssignees({
    required String taskId,
    required String instanceId,
    String? status,
    String? priority,
    List<String>? assigneeIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.updateInstanceStatusPriorityAssignees(
      taskId: taskId,
      instanceId: instanceId,
      status: status,
      priority: priority,
      assigneeIds: assigneeIds,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstanceModel>;
      _successMessage = apiResponse.message;

      final index = _instances.indexWhere(
        (element) => element.id == instanceId,
      );
      if (index != -1 && apiResponse.data != null) {
        _instances[index] = apiResponse.data!;
      }
      if (_selectedInstance?.id == instanceId) {
        _selectedInstance = apiResponse.data;
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

  /// 5. Upload Proof Files for an Instance
  Future<bool> handleUploadInstanceProofFiles({
    required String taskId,
    required String instanceId,
    required List<File> proofFiles,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.uploadInstanceProofFiles(
      taskId: taskId,
      instanceId: instanceId,
      proofFiles: proofFiles,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstanceModel>;
      _successMessage = apiResponse.message;

      final index = _instances.indexWhere(
        (element) => element.id == instanceId,
      );
      if (index != -1 && apiResponse.data != null) {
        _instances[index] = apiResponse.data!;
      }
      if (_selectedInstance?.id == instanceId) {
        _selectedInstance = apiResponse.data;
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

  /// 6. Delete a single already-uploaded proof file from an instance,
  /// identified by its cloud storage `publicId`.
  Future<bool> handleDeleteInstanceProofFile({
    required String taskId,
    required String instanceId,
    required String publicId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.deleteInstanceProofFile(
      taskId: taskId,
      instanceId: instanceId,
      publicIds: [publicId],
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<TaskInstanceModel>;
      _successMessage = apiResponse.message;

      // This endpoint's response body has, in practice, come back missing
      // the rest of the proof list instead of just the deleted file — so
      // rather than trusting it verbatim (which wiped every proof, not
      // just the one requested), prune only the just-deleted publicId from
      // what we already know locally.
      ProofSubmissionModel? pruneDeleted(ProofSubmissionModel? submission) {
        if (submission == null) return null;
        return ProofSubmissionModel(
          submittedAt: submission.submittedAt,
          files: submission.files
              .where((f) => f.file?.publicId != publicId)
              .toList(),
          note: submission.note,
          proofTypes: submission.proofTypes,
          proofEnabled: submission.proofEnabled,
        );
      }

      final index = _instances.indexWhere(
        (element) => element.id == instanceId,
      );
      if (index != -1) {
        _instances[index] = _instances[index].copyWith(
          proofSubmission: pruneDeleted(_instances[index].proofSubmission),
        );
      }
      if (_selectedInstance?.id == instanceId) {
        _selectedInstance = _selectedInstance!.copyWith(
          proofSubmission: pruneDeleted(_selectedInstance!.proofSubmission),
        );
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

  /// 7. Delete a task instance
  Future<bool> handleDeleteInstance({
    required String taskId,
    required String instanceId,
    required String scope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.deleteInstance(
      taskId: taskId,
      instanceId: instanceId,
      scope: scope,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
      _instances.removeWhere((element) => element.id == instanceId);
      if (_selectedInstance?.id == instanceId) {
        _selectedInstance = null;
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

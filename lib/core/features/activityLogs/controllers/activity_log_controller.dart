import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import '../../activityLogs/data/models/activity_log_model.dart';
import '../../activityLogs/data/repositories/activity_log_repository.dart';

class ActivityLogController extends ChangeNotifier {
  final ActivityLogRepository _repository;

  ActivityLogController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ActivityLogModel> _logs = [];
  List<ActivityLogModel> get logs => _logs;

  ActivityLogInstanceMeta? _instanceMeta;
  ActivityLogInstanceMeta? get instanceMeta => _instanceMeta;

  int _totalLogsCount = 0;
  int get totalLogsCount => _totalLogsCount;

  /// Fetches system action logs filtered down to specific instance operations trail
  Future<void> handleGetInstanceActivityLogs({
    required String instanceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getInstanceActivityLogs(
      instanceId: instanceId,
    );
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<ActivityLogResponse>;

      _logs = apiResponse.data?.logs ?? [];
      _instanceMeta = apiResponse.data?.instanceMeta;
      _totalLogsCount = apiResponse.data?.total ?? 0;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }
}

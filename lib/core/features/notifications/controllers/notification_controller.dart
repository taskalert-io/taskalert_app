import 'package:flutter/material.dart';
import '../../../network/api_result.dart';
import '../../../network/base_api_response.dart';
import '../../pagination/models/pagination_model.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationController(this._repository);

  // --- State Variables ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  int get unreadCount =>
      _notifications.where((n) => n.isRead != true).length;

  // --- Helper Methods ---
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // --- API Handlers ---

  /// 1. Fetch All Notifications
  Future<void> handleGetNotifications({int? page}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getNotifications(page: page);
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data
              as BaseApiResponse<List<NotificationModel>>;
      _notifications = apiResponse.data ?? [];
      _pagination = apiResponse.pagination;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Mark Every Notification As Read
  Future<bool> handleMarkAllRead() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.markAllRead();
    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }
    return false;
  }

  /// 3. Mark A Single Notification As Read
  Future<bool> handleMarkRead({required String id}) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.markRead(id: id);

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<NotificationModel>;
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] =
            apiResponse.data ?? _notifications[index].copyWith(isRead: true);
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

import 'package:flutter/material.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository.dart';
import '../../../../core/network/api_result.dart'; // Adjust imports to match your project path
import '../../../../core/network/base_api_response.dart';
import '../data/models/department_model.dart';

class DepartmentController extends ChangeNotifier {
  final DepartmentRepository _departmentRepository;

  DepartmentController(this._departmentRepository);

  // States
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // Cached lists/objects for the UI
  List<DepartmentModel> _departments = [];
  List<DepartmentModel> get departments => _departments;

  List<DepartmentModel> _suggestions = [];
  List<DepartmentModel> get suggestions => _suggestions;

  DepartmentModel? _selectedDepartment;
  DepartmentModel? get selectedDepartment => _selectedDepartment;

  /// Helper to clear feedback banners
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. GET: Fetch All Departments
  Future<void> handleGetDepartments({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _departmentRepository.getDepartments(search: search);

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<DepartmentModel>>;
      _departments = apiResponse.data ?? [];
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. POST: Create Department
  Future<bool> handleCreateDepartment({required String name}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _departmentRepository.createDepartment(name: name);
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<DepartmentModel>;
      _successMessage = apiResponse.message;

      // Dynamic State Sync: Insert the newly created department straight into our local view list
      if (apiResponse.data != null) {
        _departments.insert(0, apiResponse.data!);
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

  /// 3. PUT: Update Department
  Future<bool> handleUpdateDepartment({
    required String id,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _departmentRepository.updateDepartment(
      id: id,
      name: name,
    );
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<DepartmentModel>;
      _successMessage = apiResponse.message;

      // Dynamic State Sync: Find and modify the item directly in our memory array
      final index = _departments.indexWhere((element) => element.id == id);
      if (index != -1 && apiResponse.data != null) {
        _departments[index] = apiResponse.data!;
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

  /// 4. DELETE: Remove Department
  Future<bool> handleDeleteDepartment({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _departmentRepository.deleteDepartment(id: id);
    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;

      // Dynamic State Sync: Evict the item from the localized list instantly
      _departments.removeWhere((element) => element.id == id);
      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }
    return false;
  }

  /// 5. GET: Live Text Search Suggestions
  Future<void> handleGetDepartmentSuggestions({required String query}) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    final result = await _departmentRepository.getDepartmentSuggestions(
      query: '',
    );

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<DepartmentModel>>;
      _suggestions = apiResponse.data ?? [];
    }
    notifyListeners();
  }

  /// 6. GET: Single Department by ID
  Future<void> handleGetDepartmentById({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedDepartment = null;
    notifyListeners();

    final result = await _departmentRepository.getDepartmentById(id: id);
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<DepartmentModel>;
      _selectedDepartment = apiResponse.data;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }
}

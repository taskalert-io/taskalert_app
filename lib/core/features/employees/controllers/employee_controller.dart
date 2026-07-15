import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/employees/data/repositories/employee_repository.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../data/models/employee_model.dart';

class EmployeeController extends ChangeNotifier {
  final EmployeeRepository _employeeRepository;

  EmployeeController(this._employeeRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> get employees => _employees;

  List<EmployeeModel> _allEmployees = [];
  List<EmployeeModel> get allEmployees => _allEmployees;

  List<EmployeeModel> _recommendations = [];
  List<EmployeeModel> get recommendations => _recommendations;

  EmployeeModel? _selectedEmployee;
  EmployeeModel? get selectedEmployee => _selectedEmployee;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch All Employees
  Future<void> handleGetEmployees({
    String? organizationId,
    String? jobRole,
    String? search,
    int? page,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.getEmployees(
        organizationId: organizationId ?? '',
        jobRole: jobRole,
        search: search,
        page: page,
        department: department,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<List<EmployeeModel>>;

        if (department != null) {
          _employees = apiResponse.data ?? [];
        } else {
          _allEmployees = apiResponse.data ?? [];
        }

        _pagination = apiResponse
            .pagination; // Capture automatic pagination tracking fields safely
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. Fetch Single Employee
  Future<void> handleGetEmployeeById({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.getEmployeeById(id: id);

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<EmployeeModel>;
        _selectedEmployee = apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Create Employee
  Future<bool> handleCreateEmployee({
    required String firstName,
    required String lastName,
    String? email,
    required String phoneNumber,
    String? jobRole,
    String? department,
    String? gender,
    String? organization,
    String? location,
    String? dateOfBirth,
    bool? taskPermission,
    String? taskType,
    String? imageFilePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.createEmployee(
        firstName: firstName,
        lastName: lastName,
        email: email ?? '',
        phoneNumber: phoneNumber,
        jobRole: jobRole,
        imageFilePath: imageFilePath,
        gender: gender ?? '',
        department: department,
        organization: organization,
        location: location,
        dateOfBirth: dateOfBirth,
        taskPermission: taskPermission,
        taskType: taskType,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<EmployeeModel>;
        _successMessage = apiResponse.message;
        // Deliberately not optimistically inserted here: the create
        // endpoint's response returns location/department/jobRole as
        // unresolved ref ids rather than names (unlike the list endpoint),
        // so doing that briefly showed raw ids in the UI until the caller's
        // follow-up handleGetEmployees() refresh replaced it. The caller is
        // expected to re-fetch the list on success instead.
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

  /// 4. Update Employee
  Future<bool> handleUpdateEmployee({
    required String id,
    required String firstName,
    required String lastName,
    String? email,
    required String phoneNumber,
    String? jobRole,
    String? department,
    String? gender,
    String? organization,
    String? location,
    String? dateOfBirth,
    bool? taskPermission,
    String? taskType,
    String? imageFilePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.updateEmployee(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        jobRole: jobRole,
        imageFilePath: imageFilePath,
        gender: gender ?? '',
        department: department,
        organization: organization,
        location: location,
        dateOfBirth: dateOfBirth,
        taskPermission: taskPermission,
        taskType: taskType,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<EmployeeModel>;
        _successMessage = apiResponse.message;
        // Deliberately not applied to the local lists here — same reason as
        // handleCreateEmployee: the update response's location/department/
        // jobRole come back as unresolved ref ids, not names. The caller is
        // expected to re-fetch the list on success instead.
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

  /// 5. Delete Employee
  Future<bool> handleDeleteEmployee({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.deleteEmployee(id: id);

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<dynamic>;
        _successMessage = apiResponse.message;
        _employees.removeWhere((element) => element.id == id);
        _allEmployees.removeWhere((element) => element.id == id);
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

  /// 6. Live Recommendations Real-Time Text Query
  Future<void> handleGetRecommendations({
    required String query,
    String? jobRole,
  }) async {
    if (query.isEmpty) {
      _recommendations = [];
      notifyListeners();
      return;
    }

    final result = await _employeeRepository.getEmployeeRecommendations(
      search: query,
      jobRole: jobRole,
    );

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<EmployeeModel>>;
      _recommendations = apiResponse.data ?? [];
    }
    notifyListeners();
  }

  /// 7. Look Up Employee By Email Or Phone
  Future<EmployeeModel?> handleFindEmployeeByEmailOrPhone({
    String? email,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _employeeRepository.findEmployeeByEmailOrPhone(
        email: email,
        phoneNumber: phoneNumber,
      );

      if (result is Success) {
        final apiResponse =
            (result as Success).data as BaseApiResponse<EmployeeModel>;
        return apiResponse.data;
      } else if (result is Failure) {
        _errorMessage = (result as Failure).exception.userMessage;
        return null;
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

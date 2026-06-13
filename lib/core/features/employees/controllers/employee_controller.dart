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

    final result = await _employeeRepository.getEmployees(
      organizationId: organizationId ?? '',
      jobRole: jobRole,
      search: search,
      page: page,
      department: department,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<EmployeeModel>>;
      _employees = apiResponse.data ?? [];

      // print all employee names for debugging
      // print(
      //   "Fetched employees: ${_employees.map((e) => e.fullName).join(", ")}",
      // );
      _pagination = apiResponse
          .pagination; // Capture automatic pagination tracking fields safely
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Create Employee
  Future<bool> handleCreateEmployee({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String jobRole,
    String? imageFilePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _employeeRepository.createEmployee(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      jobRole: jobRole,
      imageFilePath: imageFilePath,
      gender: '',
      department: '',
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<EmployeeModel>;
      _successMessage = apiResponse.message;
      if (apiResponse.data != null) {
        _employees.insert(
          0,
          apiResponse.data!,
        ); // Optimistically prepend to active local arrays list view
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

  /// 3. Update Employee
  Future<bool> handleUpdateEmployee({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String jobRole,
    String? imageFilePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _employeeRepository.updateEmployee(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      jobRole: jobRole,
      imageFilePath: imageFilePath,
      gender: '',
      department: '',
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<EmployeeModel>;
      _successMessage = apiResponse.message;

      final index = _employees.indexWhere((element) => element.id == id);
      if (index != -1 && apiResponse.data != null) {
        _employees[index] = apiResponse.data!;
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

  /// 4. Delete Employee
  Future<bool> handleDeleteEmployee({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _employeeRepository.deleteEmployee(id: id);
    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
      _employees.removeWhere((element) => element.id == id);
      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }
    return false;
  }

  /// 5. Live Recommendations Real-Time Text Query
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
}

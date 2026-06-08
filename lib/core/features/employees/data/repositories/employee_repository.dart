import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../data/models/employee_model.dart';

abstract class EmployeeRepository {
  Future<ApiResult<BaseApiResponse<EmployeeModel>>> createEmployee({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String jobRole,
    required String gender, // 🌟 Added
    required String department,
    String? imageFilePath, // Path to local file picked from gallery/camera
  });

  Future<ApiResult<BaseApiResponse<List<EmployeeModel>>>> getEmployees({
    required String organizationId,
    String? jobRole,
    String? search,
    int? page,
    String? department,
  });

  Future<ApiResult<BaseApiResponse<EmployeeModel>>> getEmployeeById({
    required String id,
  });

  Future<ApiResult<BaseApiResponse<EmployeeModel>>> updateEmployee({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String jobRole,
    required String gender, // 🌟 Added
    required String department,
    String? imageFilePath,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> deleteEmployee({
    required String id,
  });

  Future<ApiResult<BaseApiResponse<List<EmployeeModel>>>>
  getEmployeeRecommendations({
    required String search,
    String? jobRole,
    int? page,
  });
}

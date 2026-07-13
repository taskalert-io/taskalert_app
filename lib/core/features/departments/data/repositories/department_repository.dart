// import 'package:core/core.dart';
import 'package:taskalert_app/core/features/departments/data/models/department_model.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';

abstract class DepartmentRepository {
  Future<ApiResult<BaseApiResponse<DepartmentModel>>> createDepartment({
    required String name,
    String? location,
    List<String>? locationIds,
  });
  Future<ApiResult<BaseApiResponse<List<DepartmentModel>>>> getDepartments({
    String? search,
  });
  Future<ApiResult<BaseApiResponse<DepartmentModel>>> updateDepartment({
    required String id,
    required String name,
    String? location,
    List<String>? locationIds,
  });
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteDepartment({
    required String id,
  });
  Future<ApiResult<BaseApiResponse<List<DepartmentModel>>>>
  getDepartmentSuggestions({required String query});

  Future<ApiResult<BaseApiResponse<DepartmentModel>>> getDepartmentById({
    required String id,
  });
}

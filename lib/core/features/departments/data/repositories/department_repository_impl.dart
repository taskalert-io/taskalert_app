import 'package:taskalert_app/core/errors/network_exceptions.dart';
import 'package:taskalert_app/core/features/departments/data/repositories/department_repository.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/network/http_service.dart';
import '../models/department_model.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  final HttpService _httpService;

  DepartmentRepositoryImpl(this._httpService);

  /// 1. POST: Create a new department
  @override
  Future<ApiResult<BaseApiResponse<DepartmentModel>>> createDepartment({
    required String name,
    String? location,
    List<String>? locationIds,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/departments',
        body: {
          'name': name,
          if (locationIds != null)
            'location': locationIds
          else if (location != null)
            'location': location,
        },
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => DepartmentModel.fromJson(json),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 2. GET: Fetch all departments
  /// 2. GET: Fetch all departments
  @override
  Future<ApiResult<BaseApiResponse<List<DepartmentModel>>>> getDepartments({
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
        // Optional: Limit results for search queries
      }
      queryParameters['limit'] = 100;

      // Note: Make sure your HttpService uses 'queryParams' or 'queryParameters' matching its parameter name
      final responseData = await _httpService.get(
        '/departments',
        queryParams: queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          // dataJson is now safely recognized as dynamic, so we can check and map it
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      DepartmentModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <DepartmentModel>[]; // Fallback to an empty typed collection
        },
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 3. PUT: Update an existing department by Object ID
  @override
  Future<ApiResult<BaseApiResponse<DepartmentModel>>> updateDepartment({
    required String id,
    required String name,
    String? location,
    List<String>? locationIds,
  }) async {
    try {
      final responseData = await _httpService.put(
        '/departments/$id',
        body: {
          'name': name,
          if (locationIds != null)
            'location': locationIds
          else if (location != null)
            'location': location,
        },
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => DepartmentModel.fromJson(json),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 4. DELETE: Permanently or soft-remove a department by Object ID
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteDepartment({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.delete('/departments/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) =>
            json, // Returning raw json wrapper payload on complete erase confirmations
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 5. GET: Fetch structural suggestions list based on text pattern matching
  @override
  Future<ApiResult<BaseApiResponse<List<DepartmentModel>>>>
  getDepartmentSuggestions({required String query}) async {
    try {
      final responseData = await _httpService.get(
        '/departments/search',
        queryParams: {'search': query},
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => (json as List)
            .map(
              (item) => DepartmentModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 6. GET: Fetch one target department payload exclusively via its individual ID link
  @override
  Future<ApiResult<BaseApiResponse<DepartmentModel>>> getDepartmentById({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.get('/departments/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData,
        (json) => DepartmentModel.fromJson(json),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      // Guards against unexpected response shapes (e.g. a ref field the
      // backend populates differently than expected) so a parsing bug
      // surfaces as a normal failure instead of an uncaught exception
      // that leaves the controller's loading state stuck forever.
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }
}

import 'package:dio/dio.dart';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../../network/http_service.dart';
import 'employee_repository.dart';
import '../models/employee_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final HttpService _httpService;

  EmployeeRepositoryImpl(this._httpService);

  /// 1. POST: Create Employee (with optional profile image upload)
  @override
  Future<ApiResult<BaseApiResponse<EmployeeModel>>> createEmployee({
    required String firstName,
    required String lastName,
    String? email,
    required String phoneNumber,
    required String gender,
    String? jobRole,
    String? department,
    String? organization,
    String? location,
    String? dateOfBirth,
    bool? taskPermission,
    String? taskType,
    String? imageFilePath,
  }) async {
    try {
      // 🌟 Constructing MultiPart Form-Data
      final Map<String, dynamic> map = {
        'firstName': firstName,
        'lastName': lastName,
        // 'email': email,
        'phoneNumber': phoneNumber,
        // 'gender': gender,
        'location': location,
      };

      if (email != null && email.isNotEmpty) {
        map['email'] = email;
      }

      if (gender != null && gender.isNotEmpty) {
        map['gender'] = gender;
      }

      if (jobRole != null && jobRole.isNotEmpty) {
        map['jobRole'] = jobRole;
      }
      if (department != null && department.isNotEmpty) {
        map['department'] = department;
      }
      if (organization != null && organization.isNotEmpty) {
        map['organization'] = organization;
      }
      if (location != null && location.isNotEmpty) {
        map['location'] = location;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        map['dateOfBirth'] = dateOfBirth;
      }
      if (taskPermission != null) {
        map['taskPermission'] = taskPermission.toString();
      }
      if (taskType != null && taskType.isNotEmpty) {
        map['taskType'] = taskType;
      }

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final String fileName = imageFilePath.split('/').last;
        map['image'] = await MultipartFile.fromFile(
          imageFilePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.post(
        '/employees',
        body: formData, // Passes the Form-Data structure
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => EmployeeModel.fromJson(json as Map<String, dynamic>),
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

  /// 2. GET: Fetch all employees based on organization with optional filtering queries
  @override
  Future<ApiResult<BaseApiResponse<List<EmployeeModel>>>> getEmployees({
    String? organizationId,
    String? jobRole,
    String? search,
    int? page,
    String? department,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'organization': organizationId ?? '',
      };
      if (jobRole != null) queryParameters['jobRole'] = jobRole;
      if (search != null) queryParameters['search'] = search;
      if (page != null) queryParameters['page'] = page;
      if (department != null) queryParameters['department'] = department;

      final responseData = await _httpService.get(
        '/employees',
        queryParams: queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      EmployeeModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <EmployeeModel>[];
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

  /// 3. GET: Fetch single employee metadata details exclusively via Object ID Link
  @override
  Future<ApiResult<BaseApiResponse<EmployeeModel>>> getEmployeeById({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.get('/employees/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => EmployeeModel.fromJson(json as Map<String, dynamic>),
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

  /// 4 & 5. PUT: Dynamic Employee File Updates
  @override
  Future<ApiResult<BaseApiResponse<EmployeeModel>>> updateEmployee({
    required String id,
    required String firstName,
    required String lastName,
    String? email,
    required String phoneNumber,
    required String gender,
    String? jobRole,
    String? department,
    String? organization,
    String? location,
    String? dateOfBirth,
    bool? taskPermission,
    String? taskType,
    String? imageFilePath,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'firstName': firstName,
        'lastName': lastName,
        // 'email': email,
        'phoneNumber': phoneNumber,
        // 'gender': gender,
      };

      if (email != null && email.isNotEmpty) {
        map['email'] = email;
      }

      if (gender != null && gender.isNotEmpty) {
        map['gender'] = gender;
      }

      if (jobRole != null && jobRole.isNotEmpty) {
        map['jobRole'] = jobRole;
      }
      if (department != null && department.isNotEmpty) {
        map['department'] = department;
      }
      if (organization != null && organization.isNotEmpty) {
        map['organization'] = organization;
      }
      if (location != null && location.isNotEmpty) {
        map['location'] = location;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        map['dateOfBirth'] = dateOfBirth;
      }
      if (taskPermission != null) {
        map['taskPermission'] = taskPermission.toString();
      }
      if (taskType != null && taskType.isNotEmpty) {
        map['taskType'] = taskType;
      }

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final String fileName = imageFilePath.split('/').last;
        map['image'] = await MultipartFile.fromFile(
          imageFilePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.put(
        '/employees/$id',
        body: formData,
        // queryParams: ,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => EmployeeModel.fromJson(json as Map<String, dynamic>),
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

  /// 6. DELETE: Permanently evict target profile entry tracking row parameters
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteEmployee({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.delete('/employees/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => json,
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

  /// 7. GET: Real-time lookups recommendation search parameters array collection
  @override
  Future<ApiResult<BaseApiResponse<List<EmployeeModel>>>>
  getEmployeeRecommendations({
    required String search,
    String? jobRole,
    int? page,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {'search': search};
      if (jobRole != null) queryParameters['jobRole'] = jobRole;
      if (page != null) queryParameters['page'] = page;

      final responseData = await _httpService.get(
        '/employees/search',
        queryParams: queryParameters,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      EmployeeModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <EmployeeModel>[];
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

  /// 8. POST: Look up an employee by email or phone number
  @override
  Future<ApiResult<BaseApiResponse<EmployeeModel>>> findEmployeeByEmailOrPhone({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phoneNumber'] = phoneNumber;
      }

      final responseData = await _httpService.post(
        '/employees/find-by-email-or-phone',
        body: body,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => EmployeeModel.fromJson(json as Map<String, dynamic>),
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

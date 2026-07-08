import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../models/location_model.dart';
import 'location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final HttpService _httpService;

  LocationRepositoryImpl(this._httpService);

  /// 1. GET: Fetch all locations
  @override
  Future<ApiResult<BaseApiResponse<List<LocationModel>>>> getLocations() async {
    try {
      final responseData = await _httpService.get('/locations');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      LocationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <LocationModel>[];
        },
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      print("\u274c Location API Operation Failed Error Message: ${apiResponse.message}");
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
      print("\u274c Location API Operation Failed: $e");
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 2. GET: Fetch a single location by its Unique ID
  @override
  Future<ApiResult<BaseApiResponse<LocationModel>>> getLocationById({
    required String locationId,
  }) async {
    try {
      final responseData = await _httpService.get('/locations/$locationId');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => LocationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      print("\u274c Location API Operation Failed Error Message: ${apiResponse.message}");
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
      print("\u274c Location API Operation Failed: $e");
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 3. POST: Create a new location entry
  @override
  Future<ApiResult<BaseApiResponse<LocationModel>>> createLocation({
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "name": name,
        "phoneNumber": phoneNumber,
        "address": {
          "street": street,
          "city": city,
          "state": state,
          "pinCode": pinCode,
          "country": country,
        },
      };

      final responseData = await _httpService.post('/locations', body: body);

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => LocationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      print("\u274c Location API Operation Failed Error Message: ${apiResponse.message}");
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
      print("\u274c Location API Operation Failed: $e");
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 4. PUT: Update an existing location record config
  @override
  Future<ApiResult<BaseApiResponse<LocationModel>>> updateLocation({
    required String locationId,
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "name": name,
        "phoneNumber": phoneNumber,
        "address": {
          "street": street,
          "city": city,
          "state": state,
          "pinCode": pinCode,
          "country": country,
        },
      };

      final responseData = await _httpService.put(
        '/locations/$locationId',
        body: body,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => LocationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      print("\u274c Location API Operation Failed Error Message: ${apiResponse.message}");
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
      print("\u274c Location API Operation Failed: $e");
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }

  /// 5. DELETE: Remove an existing location mapping record
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteLocation({
    required String locationId,
  }) async {
    try {
      final responseData = await _httpService.delete('/locations/$locationId');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => json, // Maps dynamic variant body seamlessly
      );

      if (apiResponse.success) return ApiResult.success(apiResponse);

      print("\u274c Location API Operation Failed Error Message: ${apiResponse.message}");
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
      print("\u274c Location API Operation Failed: $e");
      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: 'Something went wrong while processing the response.',
        ),
      );
    }
  }
}

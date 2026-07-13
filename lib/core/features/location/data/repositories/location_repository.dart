import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../models/location_model.dart';

abstract class LocationRepository {
  Future<ApiResult<BaseApiResponse<List<LocationModel>>>> getLocations({
    String? department,
    int? page,
    int? limit,
  });

  Future<ApiResult<BaseApiResponse<LocationModel>>> getLocationById({
    required String locationId,
  });

  Future<ApiResult<BaseApiResponse<LocationModel>>> createLocation({
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
    List<String>? departmentIds,
  });

  Future<ApiResult<BaseApiResponse<LocationModel>>> updateLocation({
    required String locationId,
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
    List<String>? departmentIds,
  });

  Future<ApiResult<BaseApiResponse<dynamic>>> deleteLocation({
    required String locationId,
  });
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../network/api_result.dart';
import '../../../../network/base_api_response.dart';
import '../../../../network/http_service.dart';
import 'package:taskalert_app/core/errors/network_exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/organization_model.dart';
import 'organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final HttpService _httpService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  OrganizationRepositoryImpl(this._httpService);

  /// 1. POST: Create Organization (with optional multi-part logo image file)
  ///
  ///
  ///
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
    required String name,
    required String email,
    required String phoneNumber,
    required String imageFilePath,
    String? street,
    String? city,
    String? state,
    String? country,
    String? pinCode,
  }) async {
    try {
      // 1. Initialize an empty FormData object
      final formData = FormData();

      // 2. Add text fields FIRST (Crucial for sequential backend parsing)
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('email', email),
        MapEntry('phoneNumber', phoneNumber),
      ]);

      // // Flatten and add optional address strings sequentially
      // if (street != null && street.isNotEmpty) {
      //   formData.fields.add(MapEntry('street', street));
      // }
      // if (city != null && city.isNotEmpty) {
      //   formData.fields.add(MapEntry('city', city));
      // }
      // if (state != null && state.isNotEmpty) {
      //   formData.fields.add(MapEntry('state', state));
      // }
      // if (country != null && country.isNotEmpty) {
      //   formData.fields.add(MapEntry('country', country));
      // }
      // if (pinCode != null && pinCode.isNotEmpty) {
      //   formData.fields.add(MapEntry('pinCode', pinCode));
      // }

      final Map<String, dynamic> addressMap = {};
      if (street != null && street.isNotEmpty) addressMap['street'] = street;
      if (city != null && city.isNotEmpty) addressMap['city'] = city;
      if (state != null && state.isNotEmpty) addressMap['state'] = state;
      if (country != null && country.isNotEmpty) {
        addressMap['country'] = country;
      }
      if (pinCode != null && pinCode.isNotEmpty) {
        addressMap['pinCode'] = pinCode;
      }

      // Only add the address field if at least one parameter was provided
      if (addressMap.isNotEmpty) {
        formData.fields.add(MapEntry('address', jsonEncode(addressMap)));
      }

      // 3. Attach the mandatory file payload LAST
      final String fileName = imageFilePath.split('/').last;
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(imageFilePath, filename: fileName),
        ),
      );

      // Debugging: View exactly how many text fields and files are queued
      print(
        'FormData Fields: ${formData.fields.map((e) => "${e.key}: ${e.value}").toList()}',
      );
      print('FormData Files: ${formData.files.map((e) => e.key).toList()}');

      // 4. Send the request
      final responseData = await _httpService.post(
        '/organizations',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _secureStorage.write(
          key: 'user_requires_organization',
          value: 'false',
        );
        return ApiResult.success(apiResponse);
      }

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
  // @override
  // Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
  //   required String name,
  //   required String email,
  //   required String phoneNumber,
  //   required String imageFilePath,
  //   String? street,
  //   String? city,
  //   String? state,
  //   String? country,
  //   String? pinCode,
  // }) async {
  //   try {
  //     final formData = FormData();
  //     // 1. Initialize with core fields (all flat strings)
  //     final Map<String, dynamic> map = {
  //       'name': name,
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //     };

  //     // 2. FLATTEN THE ADDRESS KEYS directly into the main map structure
  //     // instead of using _buildAddressMap and jsonEncode!
  //     if (street != null && street.isNotEmpty) map['street'] = street;
  //     if (city != null && city.isNotEmpty) map['city'] = city;
  //     if (state != null && state.isNotEmpty) map['state'] = state;
  //     if (country != null && country.isNotEmpty) map['country'] = country;
  //     if (pinCode != null && pinCode.isNotEmpty) map['pinCode'] = pinCode;

  //     // 3. Attach the mandatory file payload
  //     final String fileName = imageFilePath.split('/').last;
  //     map['image'] = await MultipartFile.fromFile(
  //       imageFilePath,
  //       filename: fileName,
  //     );

  //     // 4. Wrap everything inside a FormData instance
  //     final formData = FormData.fromMap(map);

  //     print('FormData map: $map'); // Debugging: Print the FormData map

  //     // 5. Send the request
  //     final responseData = await _httpService.post(
  //       '/auth/create-organization',
  //       body: formData,
  //     );

  //     final apiResponse = BaseApiResponse.fromJson(
  //       responseData as Map<String, dynamic>,
  //       (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
  //     );

  //     if (apiResponse.success && apiResponse.data != null) {
  //       await _secureStorage.write(
  //         key: 'user_requires_organization',
  //         value: 'false',
  //       );
  //       return ApiResult.success(apiResponse);
  //     }

  //     return ApiResult.failure(
  //       NetworkException(
  //         errorType: NetworkErrorType.unknown,
  //         userMessage: apiResponse.message,
  //       ),
  //     );
  //   } on NetworkException catch (e) {
  //     return ApiResult.failure(e);
  //   }
  // }

  /// @override
  // @override
  // Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
  //   required String name,
  //   required String email,
  //   required String phoneNumber,
  //   required String imageFilePath, // Made required and non-nullable
  //   String? street,
  //   String? city,
  //   String? state,
  //   String? country,
  //   String? pinCode,
  // }) async {
  //   try {
  //     // 1. Initialize the map with core fields
  //     final Map<String, dynamic> map = {
  //       'name': name,
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //     };

  //     // 2. Build and encode the address if present
  //     final address = _buildAddressMap(
  //       street: street,
  //       city: city,
  //       state: state,
  //       country: country,
  //       pinCode: pinCode,
  //     );

  //     if (address != null) {
  //       map['address'] = jsonEncode(address);
  //     }

  //     // 3. Attach the mandatory file payload with explicit MediaType
  //     final String fileName = imageFilePath.split('/').last;
  //     final String extension = fileName.split('.').last.toLowerCase();

  //     // Normalize common image extension patterns to valid mime subtypes
  //     String mimeSubtype = 'jpeg';
  //     if (extension == 'png') mimeSubtype = 'png';
  //     if (extension == 'jpg' || extension == 'jpeg') mimeSubtype = 'jpeg';

  //     map['image'] = await MultipartFile.fromFile(
  //       imageFilePath,
  //       filename: fileName,
  //       contentType: MediaType(
  //         'image',
  //         mimeSubtype,
  //       ), // Ensures the backend middleware identifies the stream correctly
  //     );

  //     // 4. Wrap everything inside a FormData instance
  //     final formData = FormData.fromMap(map);

  //     // 5. Send the request
  //     final responseData = await _httpService.post(
  //       '/auth/create-organization',
  //       body: formData,
  //     );

  //     final apiResponse = BaseApiResponse.fromJson(
  //       responseData as Map<String, dynamic>,
  //       (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
  //     );

  //     if (apiResponse.success && apiResponse.data != null) {
  //       await _secureStorage.write(
  //         key: 'user_requires_organization',
  //         value: 'false',
  //       );
  //       return ApiResult.success(apiResponse);
  //     }

  //     return ApiResult.failure(
  //       NetworkException(
  //         errorType: NetworkErrorType.unknown,
  //         userMessage: apiResponse.message,
  //       ),
  //     );
  //   } on NetworkException catch (e) {
  //     return ApiResult.failure(e);
  //   }
  // }

  // @override
  // Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
  //   required String name,
  //   required String email,
  //   required String phoneNumber,
  //   required String imageFilePath, // Made required and non-nullable
  //   String? street,
  //   String? city,
  //   String? state,
  //   String? country,
  //   String? pinCode,
  // }) async {
  //   try {
  //     // 1. Initialize the map with core fields
  //     final Map<String, dynamic> map = {
  //       'name': name,
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //     };

  //     // 2. Build and encode the address if present
  //     final address = _buildAddressMap(
  //       street: street,
  //       city: city,
  //       state: state,
  //       country: country,
  //       pinCode: pinCode,
  //     );

  //     if (address != null) {
  //       map['address'] = jsonEncode(address);
  //     }

  //     // 3. Attach the mandatory file payload
  //     final String fileName = imageFilePath.split('/').last;
  //     map['image'] = await MultipartFile.fromFile(
  //       imageFilePath,
  //       filename: fileName,
  //     );

  //     // 4. Wrap everything inside a FormData instance
  //     final formData = FormData.fromMap(map);

  //     // 5. Send the request
  //     final responseData = await _httpService.post(
  //       '/auth/create-organization',
  //       body: formData,
  //     );

  //     final apiResponse = BaseApiResponse.fromJson(
  //       responseData as Map<String, dynamic>,
  //       (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
  //     );

  //     if (apiResponse.success && apiResponse.data != null) {
  //       await _secureStorage.write(
  //         key: 'user_requires_organization',
  //         value: 'false',
  //       );
  //       return ApiResult.success(apiResponse);
  //     }

  //     return ApiResult.failure(
  //       NetworkException(
  //         errorType: NetworkErrorType.unknown,
  //         userMessage: apiResponse.message,
  //       ),
  //     );
  //   } on NetworkException catch (e) {
  //     return ApiResult.failure(e);
  //   }
  // }

  // @override
  // Future<ApiResult<BaseApiResponse<OrganizationModel>>> createOrganization({
  //   required String name,
  //   required String email,
  //   required String phoneNumber,
  //   String? street,
  //   String? city,
  //   String? state,
  //   String? country,
  //   String? pinCode,
  //   String? imageFilePath,
  // }) async {
  //   try {
  //     final Map<String, dynamic> map = {
  //       'name': name,
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //     };

  //     final address = _buildAddressMap(
  //       street: street,
  //       city: city,
  //       state: state,
  //       country: country,
  //       pinCode: pinCode,
  //     );

  //     // A logo is now mandatory from the admin create-organization form, so
  //     // this request is (in practice) always multipart. Previously `map`
  //     // (which can hold a `MultipartFile`) was passed straight through as
  //     // the JSON body — Dio only auto-encodes multipart for an actual
  //     // `FormData` instance, so a `MultipartFile` value inside a plain Map
  //     // silently failed to serialize, and with it, every other field
  //     // (including address). Only switch to `FormData` when there's
  //     // actually a file to send, so the no-image case (e.g. the onboarding
  //     // setup dialog) keeps going out as plain JSON exactly as before.
  //     final hasImage = imageFilePath != null && imageFilePath.isNotEmpty;

  //     if (address != null) {
  //       // `FormData.fromMap` doesn't recurse into nested Maps — send the
  //       // address as a JSON string on the multipart path, same as update().
  //       map['address'] = hasImage ? jsonEncode(address) : address;
  //     }

  //     if (hasImage) {
  //       final String fileName = imageFilePath.split('/').last;
  //       map['image'] = await MultipartFile.fromFile(
  //         imageFilePath,
  //         filename: fileName,
  //       );
  //     }

  //     final responseData = await _httpService.post(
  //       '/auth/create-organization',
  //       body: hasImage ? FormData.fromMap(map) : map,
  //     );

  //     final apiResponse = BaseApiResponse.fromJson(
  //       responseData as Map<String, dynamic>,
  //       (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
  //     );

  //     if (apiResponse.success && apiResponse.data != null) {
  //       await _secureStorage.write(
  //         key: 'user_requires_organization',
  //         value: 'false',
  //       );
  //       return ApiResult.success(apiResponse);
  //     }

  //     // if (apiResponse.success) return ApiResult.success(apiResponse);
  //     return ApiResult.failure(
  //       NetworkException(
  //         errorType: NetworkErrorType.unknown,
  //         userMessage: apiResponse.message,
  //       ),
  //     );
  //   } on NetworkException catch (e) {
  //     return ApiResult.failure(e);
  //   }
  // }

  /// 2. GET: Fetch all organizations
  @override
  Future<ApiResult<BaseApiResponse<List<OrganizationModel>>>>
  getOrganizations() async {
    try {
      final responseData = await _httpService.get('/organizations');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (dataJson) {
          if (dataJson is List) {
            return dataJson
                .map(
                  (item) =>
                      OrganizationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <OrganizationModel>[];
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
    }
  }

  /// 3. GET: Fetch single organization metadata details by ID
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> getOrganizationById({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.get('/organizations/$id');

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
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
    }
  }

  /// 4. PUT: Update organization data fields and optional image payload
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>> updateOrganization({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    String? street,
    String? city,
    String? state,
    String? country,
    String? pinCode,
    String? imageFilePath,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      };

      final address = _buildAddressMap(
        street: street,
        city: city,
        state: state,
        country: country,
        pinCode: pinCode,
      );
      // Sent as a JSON string (not a nested map) since this request goes
      // out as multipart `FormData` — `FormData.fromMap` doesn't recurse
      // into nested Maps, it would just stringify it via `toString()`.
      if (address != null) map['address'] = jsonEncode(address);

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        final String fileName = imageFilePath.split('/').last;
        map['image'] = await MultipartFile.fromFile(
          imageFilePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);

      final responseData = await _httpService.put(
        '/organizations/$id',
        body: formData,
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
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
    }
  }

  /// 5. DELETE: Permanently drop an organization profile
  @override
  Future<ApiResult<BaseApiResponse<dynamic>>> deleteOrganization({
    required String id,
  }) async {
    try {
      final responseData = await _httpService.delete('/organizations/$id');

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
    }
  }

  /// 6. GET: Fetch the organization currently scoped to this session
  ///
  /// The backend returns every organization the user belongs to as a list
  /// (each entry flagged with `isActive`), not a single object — pick the
  /// active one out rather than assuming `data` is already a single map.
  @override
  Future<ApiResult<BaseApiResponse<OrganizationModel>>>
  getMyOrganization() async {
    try {
      final responseData = await _httpService.get('/organizations/me');
      final envelope = responseData as Map<String, dynamic>;
      final rawData = envelope['data'];

      Map<String, dynamic>? activeOrgJson;
      if (rawData is List) {
        final orgs = rawData.cast<Map<String, dynamic>>();
        activeOrgJson = orgs.firstWhere(
          (o) => o['isActive'] == true,
          orElse: () => orgs.isNotEmpty ? orgs.first : <String, dynamic>{},
        );
        if (activeOrgJson.isEmpty) activeOrgJson = null;
      } else if (rawData is Map<String, dynamic>) {
        activeOrgJson = rawData; // tolerate a single-object response too
      }

      final apiResponse = BaseApiResponse<OrganizationModel>(
        success: envelope['success'] ?? false,
        message: envelope['message'] ?? '',
        data: activeOrgJson != null
            ? OrganizationModel.fromJson(activeOrgJson)
            : null,
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
    }
  }

  /// 7. POST: Switch which organization the user's session is scoped to
  @override
  Future<ApiResult<BaseApiResponse<UserModel>>> switchOrganization({
    required String organizationId,
  }) async {
    try {
      final responseData = await _httpService.post(
        '/auth/switch-organization',
        body: {'organizationId': organizationId},
      );

      final apiResponse = BaseApiResponse.fromJson(
        responseData as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final user = apiResponse.data!;
        // The response may or may not include fresh tokens, depending on
        // whether the backend scopes the JWT to the active organization —
        // only overwrite what's actually present rather than assuming
        // either shape.
        if (user.token != null && user.token!.isNotEmpty) {
          await _secureStorage.write(key: 'auth_token', value: user.token!);
        }
        if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: user.refreshToken!,
          );
        }
        await _secureStorage.write(
          key: 'user_active_organization',
          value: user.activeOrganization?.name ?? '',
        );
        await _secureStorage.write(
          key: 'user_active_organization_id',
          value: user.activeOrganization?.id ?? organizationId,
        );
        return ApiResult.success(apiResponse);
      }

      return ApiResult.failure(
        NetworkException(
          errorType: NetworkErrorType.unknown,
          userMessage: apiResponse.message,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Builds the nested `address` payload only when at least one field was
  /// actually provided — so a plain name/phone/email edit (e.g. from the
  /// onboarding setup dialog, which never collects an address) doesn't
  /// accidentally overwrite an existing address with empty strings.
  Map<String, dynamic>? _buildAddressMap({
    String? street,
    String? city,
    String? state,
    String? country,
    String? pinCode,
  }) {
    final hasAny =
        (street != null && street.isNotEmpty) ||
        (city != null && city.isNotEmpty) ||
        (state != null && state.isNotEmpty) ||
        (country != null && country.isNotEmpty) ||
        (pinCode != null && pinCode.isNotEmpty);
    if (!hasAny) return null;

    return {
      'street': street ?? '',
      'city': city ?? '',
      'state': state ?? '',
      'country': country ?? '',
      'pinCode': pinCode ?? '',
    };
  }
}

import 'package:flutter/material.dart';
import '../../../network/api_result.dart';
import '../../../network/base_api_response.dart';
import '../../pagination/models/pagination_model.dart';
import '../data/models/location_model.dart';
import '../data/repositories/location_repository.dart';

class LocationController extends ChangeNotifier {
  final LocationRepository _repository;

  LocationController(this._repository);

  // --- State Variables ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<LocationModel> _locations = [];
  List<LocationModel> get locations => _locations;

  LocationModel? _selectedLocation;
  LocationModel? get selectedLocation => _selectedLocation;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  // --- Helper Methods ---
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // --- API Handlers ---

  /// 1. Fetch All Locations
  Future<void> handleGetLocations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getLocations();
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<LocationModel>>;
      _locations = apiResponse.data ?? [];
      _pagination = apiResponse.pagination;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Fetch Single Location Details
  Future<void> handleGetLocationById({required String locationId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getLocationById(locationId: locationId);
    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<LocationModel>;
      _selectedLocation = apiResponse.data;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 3. Create a Location
  Future<bool> handleCreateLocation({
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.createLocation(
      name: name,
      phoneNumber: phoneNumber,
      street: street,
      city: city,
      state: state,
      pinCode: pinCode,
      country: country,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<LocationModel>;
      _successMessage = apiResponse.message;

      // Opt-in optimization: add newly created item directly to local list state
      if (apiResponse.data != null) {
        _locations.insert(0, apiResponse.data!);
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

  /// 4. Update a Location
  Future<bool> handleUpdateLocation({
    required String locationId,
    required String name,
    required String phoneNumber,
    required String street,
    required String city,
    required String state,
    required String pinCode,
    required String country,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.updateLocation(
      locationId: locationId,
      name: name,
      phoneNumber: phoneNumber,
      street: street,
      city: city,
      state: state,
      pinCode: pinCode,
      country: country,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<LocationModel>;
      _successMessage = apiResponse.message;

      // Synchronize modified item with local tracking arrays instantly
      final index = _locations.indexWhere(
        (element) => element.id == locationId,
      );
      if (index != -1 && apiResponse.data != null) {
        _locations[index] = apiResponse.data!;
      }
      if (_selectedLocation?.id == locationId) {
        _selectedLocation = apiResponse.data;
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

  /// 5. Delete a Location
  Future<bool> handleDeleteLocation({required String locationId}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.deleteLocation(locationId: locationId);
    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;

      // Instantly wipe removed entity out from active lists
      _locations.removeWhere((element) => element.id == locationId);
      if (_selectedLocation?.id == locationId) {
        _selectedLocation = null;
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
}

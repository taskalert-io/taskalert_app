import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';
import 'package:taskalert_app/core/features/pagination/models/pagination_model.dart';
import '../../organization/data/models/organization_model.dart';
import '../../organization/data/repositories/organization_repository.dart';

class OrganizationController extends ChangeNotifier {
  final OrganizationRepository _organizationRepository;

  OrganizationController(this._organizationRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<OrganizationModel> _organizations = [];
  List<OrganizationModel> get organizations => _organizations;

  OrganizationModel? _selectedOrganization;
  OrganizationModel? get selectedOrganization => _selectedOrganization;

  OrganizationModel? _myOrganization;
  OrganizationModel? get myOrganization => _myOrganization;

  PaginationModel? _pagination;
  PaginationModel? get pagination => _pagination;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch All Organizations
  Future<void> handleGetOrganizations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _organizationRepository.getOrganizations();

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<OrganizationModel>>;

      _organizations = apiResponse.data ?? [];
      _pagination =
          apiResponse.pagination; // Capture automatic pagination fields
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Fetch Single Organization By ID
  Future<void> handleGetOrganizationById({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _organizationRepository.getOrganizationById(id: id);

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<OrganizationModel>;
      _selectedOrganization = apiResponse.data;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 3. Create Organization
  Future<bool> handleCreateOrganization({
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
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _organizationRepository.createOrganization(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      street: street,
      city: city,
      state: state,
      country: country,
      pinCode: pinCode,
      imageFilePath: imageFilePath ?? '',
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<OrganizationModel>;
      _successMessage = apiResponse.message;

      if (apiResponse.data != null) {
        _organizations.insert(0, apiResponse.data!); // Optimistically prepend
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

  /// 4. Update Organization
  Future<bool> handleUpdateOrganization({
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
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _organizationRepository.updateOrganization(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      street: street,
      city: city,
      state: state,
      country: country,
      pinCode: pinCode,
      imageFilePath: imageFilePath,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<OrganizationModel>;
      _successMessage = apiResponse.message;

      final index = _organizations.indexWhere((element) => element.id == id);
      if (index != -1 && apiResponse.data != null) {
        _organizations[index] = apiResponse.data!;
      }

      // Keep selected detail model in sync if viewing it
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = apiResponse.data;
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

  /// 5. Delete Organization
  Future<bool> handleDeleteOrganization({required String id}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _organizationRepository.deleteOrganization(id: id);
    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
      _organizations.removeWhere((element) => element.id == id);

      if (_selectedOrganization?.id == id) {
        _selectedOrganization = null;
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

  /// 6. Fetch the organization currently scoped to this session
  Future<void> handleGetMyOrganization() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _organizationRepository.getMyOrganization();

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<OrganizationModel>;
      _myOrganization = apiResponse.data;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 7. Switch which organization the user's session is scoped to
  Future<bool> handleSwitchOrganization({
    required String organizationId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _organizationRepository.switchOrganization(
      organizationId: organizationId,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
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

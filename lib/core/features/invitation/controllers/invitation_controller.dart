import 'package:flutter/material.dart';
import 'package:taskalert_app/core/network/api_result.dart';
import 'package:taskalert_app/core/network/base_api_response.dart';

import '../data/models/invitation_model.dart';
import '../data/repositories/invitation_repository.dart';

class InvitationController extends ChangeNotifier {
  final InvitationRepository _repository;

  InvitationController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<Invitation> _invitations = [];
  List<Invitation> get invitations => _invitations;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// 1. Fetch all invitations, with an optional search query
  Future<void> handleGetInvitations({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getInvitations(search: search);

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<List<Invitation>>;
      _invitations = apiResponse.data ?? [];
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
    }
    notifyListeners();
  }

  /// 2. Create and send a new organization invitation
  Future<bool> handleCreateInvitation({
    required String firstName,
    required String lastName,
    required String email,
    required String organizationId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.createInvitation(
      firstName: firstName,
      lastName: lastName,
      email: email,
      organizationId: organizationId,
    );

    _isLoading = false;

    if (result is Success) {
      final apiResponse =
          (result as Success).data as BaseApiResponse<Invitation>;
      _successMessage = apiResponse.message;

      if (apiResponse.data != null) {
        _invitations.insert(0, apiResponse.data!); // Optimistically prepend
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

  /// 3. Revoke an existing invitation by its ID
  Future<bool> handleRevokeInvitation(String id) async {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _repository.revokeInvitation(invitationId: id);

    if (result is Success) {
      final apiResponse = (result as Success).data as BaseApiResponse<dynamic>;
      _successMessage = apiResponse.message;
      _invitations.removeWhere((invite) => invite.id == id);
      notifyListeners();
      return true;
    } else if (result is Failure) {
      _errorMessage = (result as Failure).exception.userMessage;
      notifyListeners();
      return false;
    }
    return false;
  }

  /// 4. Validate a deep-linked registration token
  Future<bool> handleValidateToken(String token) async {
    final result = await _repository.validateToken(token: token);
    return result is Success;
  }
}

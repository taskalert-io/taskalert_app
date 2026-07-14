class Invitation {
  final String id;
  final String organization;
  final InvitedUser? invitedBy;
  final String role;
  final String status;
  final String token;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InvitedToUser? invitedTo;

  Invitation({
    required this.id,
    required this.organization,
    this.invitedBy,
    required this.role,
    required this.status,
    required this.token,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.invitedTo,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['_id'] ?? '',
      organization: json['organization'] ?? '',
      invitedBy: json['invitedBy'] != null
          ? InvitedUser.fromJson(json['invitedBy'])
          : null,
      role: json['role'] ?? 'employee',
      status: json['status'] ?? 'pending',
      token: json['token'] ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      invitedTo: json['invitedTo'] != null
          ? InvitedToUser.fromJson(json['invitedTo'])
          : null,
    );
  }
}

class InvitedUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  InvitedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory InvitedUser.fromJson(Map<String, dynamic> json) {
    return InvitedUser(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class InvitedToUser {
  final String firstName;
  final String lastName;
  final String email;

  InvitedToUser({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory InvitedToUser.fromJson(Map<String, dynamic> json) {
    return InvitedToUser(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

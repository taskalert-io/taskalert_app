class ProfileModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String gender;
  final DateTime? dateOfBirth;
  final ProfileImage? image;
  final ProfileOrganization? organization;
  final ProfileJobRole? jobRole;
  final ProfileDepartment? department;
  final DateTime? createdAt;
  final LanguageSettings? languageSettings;

  ProfileModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.gender,
    this.dateOfBirth,
    this.image,
    this.organization,
    this.jobRole,
    this.department,
    this.createdAt,
    this.languageSettings,
  });

  /// Computed property to instantly grab the user's combined full name
  String get fullName => "$firstName $lastName".trim();

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      image: json['image'] != null
          ? ProfileImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      organization: json['organization'] != null
          ? ProfileOrganization.fromJson(
              json['organization'] as Map<String, dynamic>,
            )
          : null,
      jobRole: json['jobRole'] != null
          ? ProfileJobRole.fromJson(json['jobRole'] as Map<String, dynamic>)
          : null,
      department: json['department'] != null
          ? ProfileDepartment.fromJson(
              json['department'] as Map<String, dynamic>,
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      languageSettings: json['languageSettings'] != null
          ? LanguageSettings.fromJson(
              json['languageSettings'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// ── Supporting Nested Profile Models ──

class ProfileImage {
  final String originalUrl;
  final String thumbnailUrl;
  final String publicId;

  ProfileImage({
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.publicId,
  });

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      originalUrl: json['originalUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class ProfileOrganization {
  final String id;
  final String name;

  ProfileOrganization({required this.id, required this.name});

  factory ProfileOrganization.fromJson(Map<String, dynamic> json) {
    return ProfileOrganization(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}

class ProfileJobRole {
  final String id;
  final String title;

  ProfileJobRole({required this.id, required this.title});

  factory ProfileJobRole.fromJson(Map<String, dynamic> json) {
    return ProfileJobRole(id: json['_id'] ?? '', title: json['title'] ?? '');
  }
}

class ProfileDepartment {
  final String id;
  final String name;

  ProfileDepartment({required this.id, required this.name});

  factory ProfileDepartment.fromJson(Map<String, dynamic> json) {
    return ProfileDepartment(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}

class LanguageSettings {
  final String language;
  final String languageCode;

  LanguageSettings({required this.language, required this.languageCode});

  factory LanguageSettings.fromJson(Map<String, dynamic> json) {
    return LanguageSettings(
      language: json['language'] ?? '',
      languageCode: json['languageCode'] ?? '',
    );
  }
}

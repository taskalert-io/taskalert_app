class EmployeeModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String>? ownedOrganizations;
  final String? activeOrganization;
  final String? signupSource;
  final String? accountType;
  final bool? taskPermission;
  final String? taskType;
  final bool? agreeTerms;
  final LanguageSettings? languageSettings;
  final EmployeeMedia? image;
  final EmployeeVideo? video;
  final bool? isDeleted;
  final List<EmployeeMembership>? memberships;
  final String? jobRole;
  final String? department;
  final String? organization;
  final String? location;
  final DateTime? createdAt;

  EmployeeModel({
    this.id,
    this.firstName,
  this.lastName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.ownedOrganizations,
    this.activeOrganization,
    this.signupSource,
    this.accountType,
    this.taskPermission,
    this.taskType,
    this.agreeTerms,
    this.languageSettings,
    this.image,
    this.video,
    this.isDeleted,
    this.memberships,
    this.jobRole,
    this.department,
    this.organization,
    this.location,
    this.createdAt,
  });

  /// Helper utility getter to display combined names cleanly in UI lists
  String get fullName => '${firstName ?? ""} ${lastName ?? ""}'.trim();

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      ownedOrganizations: (json['ownedOrganizations'] as List?)
          ?.map((e) => _extractRefDisplay(e) ?? e.toString())
          .toList(),
      activeOrganization: _extractRefDisplay(json['activeOrganization']),
      signupSource: json['signupSource'] as String?,
      accountType: json['accountType'] as String?,
      taskPermission: json['taskPermission'] as bool?,
      taskType: json['taskType'] as String?,
      agreeTerms: json['agreeTerms'] as bool?,
      languageSettings: json['languageSettings'] != null
          ? LanguageSettings.fromJson(
              json['languageSettings'] as Map<String, dynamic>,
            )
          : null,
      image: json['image'] != null
          ? EmployeeMedia.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      video: json['video'] != null
          ? EmployeeVideo.fromJson(json['video'] as Map<String, dynamic>)
          : null,
      isDeleted: json['isDeleted'] as bool?,
      memberships: (json['memberships'] as List?)
          ?.map(
            (m) => EmployeeMembership.fromJson(m as Map<String, dynamic>),
          )
          .toList(),
      jobRole: _extractRefDisplay(json['jobRole']),
      department: _extractRefDisplay(json['department']),
      organization: _extractRefDisplay(json['organization']),
      location: _extractRefDisplay(json['location']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Ref fields like `organization`/`department`/`jobRole`/`location` come
  /// back as a plain id/name string on some endpoints (e.g. the employees
  /// list) but as a populated object on others (e.g. after an update) —
  /// extract whichever display value is available so a shape mismatch
  /// doesn't throw and break the whole parse.
  static String? _extractRefDisplay(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final display = value['title'] ?? value['name'] ?? value['_id'];
      return display?.toString();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth?.toIso8601String(),
      if (ownedOrganizations != null)
        'ownedOrganizations': ownedOrganizations,
      if (activeOrganization != null)
        'activeOrganization': activeOrganization,
      if (signupSource != null) 'signupSource': signupSource,
      if (accountType != null) 'accountType': accountType,
      if (taskPermission != null) 'taskPermission': taskPermission,
      if (taskType != null) 'taskType': taskType,
      if (agreeTerms != null) 'agreeTerms': agreeTerms,
      if (languageSettings != null)
        'languageSettings': languageSettings?.toJson(),
      if (image != null) 'image': image?.toJson(),
      if (video != null) 'video': video?.toJson(),
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (memberships != null)
        'memberships': memberships?.map((m) => m.toJson()).toList(),
      if (jobRole != null) 'jobRole': jobRole,
      if (department != null) 'department': department,
      if (organization != null) 'organization': organization,
      if (location != null) 'location': location,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }
}

/// Nested Class for an organization membership entry. The `organization`,
/// `location`, `department` and `jobRole` values here are refs that may come
/// back as a plain id/name string or a populated object, same as the
/// corresponding top-level fields on EmployeeModel.
class EmployeeMembership {
  final String? organization;
  final String? role;
  final String? location;
  final String? department;
  final String? jobRole;

  EmployeeMembership({
    this.organization,
    this.role,
    this.location,
    this.department,
    this.jobRole,
  });

  factory EmployeeMembership.fromJson(Map<String, dynamic> json) {
    return EmployeeMembership(
      organization: EmployeeModel._extractRefDisplay(json['organization']),
      role: json['role'] as String?,
      location: EmployeeModel._extractRefDisplay(json['location']),
      department: EmployeeModel._extractRefDisplay(json['department']),
      jobRole: EmployeeModel._extractRefDisplay(json['jobRole']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (organization != null) 'organization': organization,
      if (role != null) 'role': role,
      if (location != null) 'location': location,
      if (department != null) 'department': department,
      if (jobRole != null) 'jobRole': jobRole,
    };
  }
}

/// Nested Class for Language Settings
class LanguageSettings {
  final String? language;
  final String? languageCode;

  LanguageSettings({this.language, this.languageCode});

  factory LanguageSettings.fromJson(Map<String, dynamic> json) {
    return LanguageSettings(
      language: json['language'] as String?,
      languageCode: json['languageCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (language != null) 'language': language,
      if (languageCode != null) 'languageCode': languageCode,
    };
  }
}

/// Nested Class for Employee Image Assets
class EmployeeMedia {
  final String? originalUrl;
  final String? thumbnailUrl;
  final String? publicId;

  EmployeeMedia({this.originalUrl, this.thumbnailUrl, this.publicId});

  factory EmployeeMedia.fromJson(Map<String, dynamic> json) {
    return EmployeeMedia(
      originalUrl: json['originalUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      publicId: json['publicId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (originalUrl != null) 'originalUrl': originalUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (publicId != null) 'publicId': publicId,
    };
  }
}

/// Nested Class for Employee Video Assets
class EmployeeVideo {
  final String? videoUrl;
  final String? publicId;

  EmployeeVideo({this.videoUrl, this.publicId});

  factory EmployeeVideo.fromJson(Map<String, dynamic> json) {
    return EmployeeVideo(
      videoUrl: json['videoUrl'] as String?,
      publicId: json['publicId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (publicId != null) 'publicId': publicId,
    };
  }
}

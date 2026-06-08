class EmployeeModel {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final bool? agreeTerms;
  final LanguageSettings? languageSettings;
  final EmployeeMedia? image;
  final EmployeeVideo? video;
  final bool? isDeleted;
  final String? jobRole;
  final String? department;
  final String? organization;

  EmployeeModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.agreeTerms,
    this.languageSettings,
    this.image,
    this.video,
    this.isDeleted,
    this.jobRole,
    this.department,
    this.organization,
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
      jobRole: json['jobRole'] as String?,
      department: json['department'] as String?,
      organization: json['organization'] as String?,
    );
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
      if (agreeTerms != null) 'agreeTerms': agreeTerms,
      if (languageSettings != null)
        'languageSettings': languageSettings?.toJson(),
      if (image != null) 'image': image?.toJson(),
      if (video != null) 'video': video?.toJson(),
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (jobRole != null) 'jobRole': jobRole,
      if (department != null) 'department': department,
      if (organization != null) 'organization': organization,
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

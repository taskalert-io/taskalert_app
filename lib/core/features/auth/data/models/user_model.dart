class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? originalAvatarUrl;
  final String? thumbnailAvatarUrl;
  final String? token; // This will cleanly map the root accessToken
  final String? refreshToken; // This will map the root refreshToken
  final String? videoUrl; // New field for video URL
  final String? accountType;
  final bool? taskPermission;
  final String? taskType;
  final bool? requiresOrganization;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? role;
  final UserOrganizationRef? organization;
  final UserOrganizationRef? activeOrganization;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.originalAvatarUrl,
    this.thumbnailAvatarUrl,
    this.token,
    this.refreshToken,
    this.videoUrl,
    this.accountType,
    this.taskPermission,
    this.taskType,
    this.requiresOrganization,
    this.gender,
    this.dateOfBirth,
    this.role,
    this.organization,
    this.activeOrganization,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe extraction of the nested user block context
    final userMap = json['user'] as Map<String, dynamic>? ?? {};

    // 2. Safe extraction of the image nested map block inside the user context
    final imageMap = userMap['image'] as Map<String, dynamic>?;

    final videoMap =
        userMap['video']
            as Map<String, dynamic>?; // New mapping for video object

    return UserModel(
      // Parse nested profile fields using target keys matching the response
      id: (userMap['userId'] ?? userMap['id'] ?? '').toString(),
      email: userMap['email'] ?? '',
      firstName: userMap['firstName'] ?? '',
      lastName: userMap['lastName'] ?? '',
      phoneNumber: (userMap['phoneNumber'] ?? '').toString(),
      accountType: (userMap['accountType'] ?? '').toString(),
      taskPermission: userMap['taskPermission'],
      taskType: (userMap['taskType'] ?? '').toString(),
      requiresOrganization: userMap['requiresOrganization'] ?? false,
      gender: userMap['gender']?.toString(),
      dateOfBirth: userMap['dateOfBirth'] != null
          ? DateTime.tryParse(userMap['dateOfBirth'].toString())
          : null,
      role: userMap['role']?.toString(),
      organization: UserOrganizationRef.fromDynamic(userMap['organization']),
      activeOrganization: UserOrganizationRef.fromDynamic(
        userMap['activeOrganization'],
      ),

      // Dig cleanly into your multi-variant image object keys
      originalAvatarUrl: imageMap?['originalUrl']?.toString(),
      thumbnailAvatarUrl: imageMap?['thumbnailUrl']?.toString(),

      videoUrl: videoMap?['videoUrl']?.toString(),

      // New mapping for video URL
      // Pull tokens straight from the base data structure root maps
      token: (json['accessToken'] ?? json['token'])?.toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }
}

/// `organization`/`activeOrganization` come back as a populated
/// `{"_id": ..., "name": ...}` object on the auth endpoints, but handle a
/// plain ID string too in case another endpoint ever sends that shape.
class UserOrganizationRef {
  final String? id;
  final String? name;

  UserOrganizationRef({this.id, this.name});

  factory UserOrganizationRef.fromJson(Map<String, dynamic> json) {
    return UserOrganizationRef(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
    );
  }

  static UserOrganizationRef? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return UserOrganizationRef.fromJson(value);
    }
    if (value is String) return UserOrganizationRef(id: value);
    return null;
  }
}

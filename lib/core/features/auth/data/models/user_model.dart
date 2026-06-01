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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe extraction of the nested user block context
    final userMap = json['user'] as Map<String, dynamic>? ?? {};

    // 2. Safe extraction of the image nested map block inside the user context
    final imageMap = userMap['image'] as Map<String, dynamic>?;

    return UserModel(
      // Parse nested profile fields using target keys matching the response
      id: (userMap['userId'] ?? userMap['id'] ?? '').toString(),
      email: userMap['email'] ?? '',
      firstName: userMap['firstName'] ?? '',
      lastName: userMap['lastName'] ?? '',
      phoneNumber: (userMap['phoneNumber'] ?? '').toString(),

      // Dig cleanly into your multi-variant image object keys
      originalAvatarUrl: imageMap?['originalUrl']?.toString(),
      thumbnailAvatarUrl: imageMap?['thumbnailUrl']?.toString(),

      // Pull tokens straight from the base data structure root maps
      token: (json['accessToken'] ?? json['token'])?.toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }
}

class OrganizationModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final OrganizationImage? image;
  final DateTime? createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.image,
    this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      image: json['image'] != null
          ? OrganizationImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'image': image?.toJson(),
    };
  }
}

class OrganizationImage {
  final String? originalUrl;
  final String? thumbnailUrl;
  final String? publicId;

  OrganizationImage({this.originalUrl, this.thumbnailUrl, this.publicId});

  factory OrganizationImage.fromJson(Map<String, dynamic> json) {
    return OrganizationImage(
      originalUrl: json['originalUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      publicId: json['publicId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalUrl': originalUrl,
      'thumbnailUrl': thumbnailUrl,
      'publicId': publicId,
    };
  }
}

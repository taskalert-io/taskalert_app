class OrganizationModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final OrganizationAddress? address;
  final OrganizationImage? image;
  final DateTime? createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.image,
    this.createdAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] != null
          ? OrganizationAddress.fromJson(
              json['address'] as Map<String, dynamic>,
            )
          : null,
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
      'address': address?.toJson(),
      'image': image?.toJson(),
    };
  }
}

class OrganizationAddress {
  final String street;
  final String city;
  final String state;
  final String country;
  final String pinCode;

  // Handy helper getter to format full address for UI views
  String get completeAddress =>
      "$street, $city, $state - $pinCode, $country".trim();

  OrganizationAddress({
    this.street = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pinCode = '',
  });

  factory OrganizationAddress.fromJson(Map<String, dynamic> json) {
    return OrganizationAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pinCode: json['pinCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'pinCode': pinCode,
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

class LocationModel {
  final String id;
  final String organization; // Hex ID string representing the organization
  final String name;
  final String phoneNumber;
  final AddressModel? address;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationModel({
    required this.id,
    required this.organization,
    required this.name,
    required this.phoneNumber,
    this.address,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] ?? '',
      organization: _extractRefId(json['organization']) ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  /// Some refs (e.g. `organization`) come back populated as `{"_id": ...}`
  /// on GET requests but as a plain ID string on POST/PUT. Handle both so
  /// a shape mismatch doesn't throw and silently break the whole fetch.
  static String? _extractRefId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) return value['_id'] as String?;
    return null;
  }
}

class AddressModel {
  final String street;
  final String city;
  final String state;
  final String pinCode;
  final String country;

  // Handy helper getter to format full address for UI views
  String get completeAddress =>
      "$street, $city, $state - $pinCode, $country".trim();

  AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pinCode: json['pinCode'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

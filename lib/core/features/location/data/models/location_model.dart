class LocationModel {
  final String id;
  final String organization; // Hex ID string representing the organization
  final String name;
  final String phoneNumber;
  final AddressModel? address;
  final List<LocationDepartmentModel> department;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationModel({
    required this.id,
    required this.organization,
    required this.name,
    required this.phoneNumber,
    this.address,
    this.department = const [],
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
      department: _parseDepartmentList(json['department']),
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

  /// `department` comes back as an array of populated objects
  /// (`[{"_id": ..., "name": ...}]`). Also tolerates a single object or
  /// plain ID string, in case an older endpoint still sends that shape.
  static List<LocationDepartmentModel> _parseDepartmentList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => LocationDepartmentModel.fromDynamic(e))
          .whereType<LocationDepartmentModel>()
          .toList();
    }
    final single = LocationDepartmentModel.fromDynamic(value);
    return single != null ? [single] : [];
  }
}

class LocationDepartmentModel {
  final String? id;
  final String? name;

  LocationDepartmentModel({this.id, this.name});

  factory LocationDepartmentModel.fromJson(Map<String, dynamic> json) {
    return LocationDepartmentModel(
      id: json['_id'] as String?,
      name: json['name'] as String?,
    );
  }

  /// Handles both shapes the API sends for this relation: a populated
  /// object (`{"_id": ..., "name": ...}`, e.g. on GET) or a plain ID
  /// string (e.g. on POST/PUT, where the ref isn't populated).
  static LocationDepartmentModel? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return LocationDepartmentModel.fromJson(value);
    }
    if (value is String) {
      return LocationDepartmentModel(id: value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) '_id': id, if (name != null) 'name': name};
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

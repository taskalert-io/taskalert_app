class DepartmentModel {
  final String? id;
  final String? name;
  final List<dynamic>?
  user; // Kept as dynamic since it's an empty array for now
  final String? organization;
  final List<DepartmentLocationModel> location;
  final bool? isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Constructor with named parameters and optional fields
  DepartmentModel({
    this.id,
    this.name,
    this.user,
    this.organization,
    this.location = const [],
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory map constructor to deserialize raw server JSON
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      user: json['user'] != null
          ? List<dynamic>.from(json['user'] as List)
          : null,
      organization: _extractRefId(json['organization']),
      location: _parseLocationList(json['location']),
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
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

  /// `location` now comes back as an array of populated objects
  /// (`[{"_id": ..., "name": ...}]`). Also tolerates a single object or
  /// plain ID string, in case an older endpoint still sends that shape.
  static List<DepartmentLocationModel> _parseLocationList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => DepartmentLocationModel.fromDynamic(e))
          .whereType<DepartmentLocationModel>()
          .toList();
    }
    final single = DepartmentLocationModel.fromDynamic(value);
    return single != null ? [single] : [];
  }

  /// Serialization payload builder for POST / PUT bodies
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (user != null) 'user': user,
      if (organization != null) 'organization': organization,
      if (location.isNotEmpty)
        'location': location.map((l) => l.toJson()).toList(),
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class DepartmentLocationModel {
  final String? id;
  final String? name;

  DepartmentLocationModel({this.id, this.name});

  factory DepartmentLocationModel.fromJson(Map<String, dynamic> json) {
    return DepartmentLocationModel(
      id: json['_id'] as String?,
      name: json['name'] as String?,
    );
  }

  /// Handles both shapes the API sends for this relation:
  /// a populated object (`{"_id": ..., "name": ...}`, e.g. on GET) or a
  /// plain ID string (e.g. on POST/PUT, where the ref isn't populated).
  static DepartmentLocationModel? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return DepartmentLocationModel.fromJson(value);
    }
    if (value is String) {
      return DepartmentLocationModel(id: value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) '_id': id, if (name != null) 'name': name};
  }
}

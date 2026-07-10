class JobRoleModel {
  final String id;
  final String title;
  final String organization; // Hex ID string representing the organization
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobRoleModel({
    required this.id,
    required this.title,
    required this.organization,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory JobRoleModel.fromJson(Map<String, dynamic> json) {
    return JobRoleModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      organization: _extractRefId(json['organization']) ?? '',
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

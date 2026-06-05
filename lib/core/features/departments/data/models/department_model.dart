class DepartmentModel {
  final String? id;
  final String? name;
  final List<dynamic>?
  user; // Kept as dynamic since it's an empty array for now
  final String? organization;
  final bool? isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DepartmentModel({
    this.id,
    this.name,
    this.user,
    this.organization,
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
      organization: json['organization'] as String?,
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serialization payload builder for POST / PUT bodies
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (name != null) 'name': name,
      if (user != null) 'user': user,
      if (organization != null) 'organization': organization,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

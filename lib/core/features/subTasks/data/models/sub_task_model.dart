/// Placeholder model for both SubTask and SubTaskInstance API responses —
/// intentionally minimal until the real field structure is provided. Only
/// `id` is parsed for now; everything else from the response is kept in
/// [raw] so it isn't lost, and can be promoted to real fields later without
/// touching the repository/controller call sites.
class SubTaskModel {
  final String id;
  final Map<String, dynamic> raw;

  SubTaskModel({required this.id, this.raw = const {}});

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(id: json['_id']?.toString() ?? '', raw: json);
  }
}

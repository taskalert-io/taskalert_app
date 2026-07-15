class SidebarConfigModel {
  final String accountType;
  final String role;
  final String plan;
  final List<SidebarItemModel> sidebar;

  SidebarConfigModel({
    required this.accountType,
    required this.role,
    required this.plan,
    required this.sidebar,
  });

  factory SidebarConfigModel.fromJson(Map<String, dynamic> json) {
    return SidebarConfigModel(
      accountType: json['accountType'] ?? '',
      role: json['role'] ?? '',
      plan: json['plan'] ?? '',
      sidebar: json['sidebar'] != null
          ? (json['sidebar'] as List)
                .map(
                  (item) =>
                      SidebarItemModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class SidebarItemModel {
  final String key;
  final String label;
  final String path;
  final List<SidebarItemModel> children;

  bool get hasChildren => children.isNotEmpty;

  SidebarItemModel({
    required this.key,
    required this.label,
    required this.path,
    required this.children,
  });

  factory SidebarItemModel.fromJson(Map<String, dynamic> json) {
    return SidebarItemModel(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      path: json['path'] ?? '',
      children: json['children'] != null
          ? (json['children'] as List)
                .map(
                  (item) =>
                      SidebarItemModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

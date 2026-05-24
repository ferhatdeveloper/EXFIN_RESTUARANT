class MenuItemModel {
  final String id;
  final String title;
  final String route;
  final String icon;
  final List<String> requiredPermissions;
  final bool isEnabled;

  MenuItemModel({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    required this.requiredPermissions,
    this.isEnabled = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      route: json['route'] ?? '',
      icon: json['icon'] ?? '',
      requiredPermissions:
          List<String>.from(json['required_permissions'] ?? []),
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'route': route,
      'icon': icon,
      'required_permissions': requiredPermissions,
      'is_enabled': isEnabled,
    };
  }
}

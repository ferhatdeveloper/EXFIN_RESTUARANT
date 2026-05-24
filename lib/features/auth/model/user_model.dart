class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? fullName;
  final bool isActive;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fullName,
    required this.isActive,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // id alanını güvenli şekilde int'e çevir
    int userId;
    if (json['id'] is int) {
      userId = json['id'];
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id']) ?? 0;
    } else {
      userId = 0;
    }

    return UserModel(
      id: userId,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      fullName: json['fullName'] ?? json['full_name'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : json['last_login'] != null
              ? DateTime.parse(json['last_login'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'full_name': fullName,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? fullName,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

enum UserRole {
  admin,
  user;

  bool get isAdmin => this == UserRole.admin;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'User';
    }
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;

  factory User.fromJson(Map<String, Object?> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: (json['role'] as String?) == 'admin'
          ? UserRole.admin
          : UserRole.user,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'avatar_url': avatarUrl,
    };
  }
}

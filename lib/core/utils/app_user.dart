class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool? isActive;
  final DateTime? deletedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive,
    this.deletedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'student',
      isActive: map['is_active'] as bool?,
      deletedAt: map['deleted_at'] != null 
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

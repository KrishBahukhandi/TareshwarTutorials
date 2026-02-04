class TeacherProfile {
  final String id;
  final String name;
  final String email;
  final bool isActive;

  const TeacherProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
  });

  TeacherProfile copyWith({
    bool? isActive,
  }) {
    return TeacherProfile(
      id: id,
      name: name,
      email: email,
      isActive: isActive ?? this.isActive,
    );
  }
}

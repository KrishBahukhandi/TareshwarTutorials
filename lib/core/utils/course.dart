class Course {
  final String id;
  final String title;
  final String description;
  final double price;
  final String createdBy;
  final bool isPublished;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.createdBy,
    required this.isPublished,
    required this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      createdBy: (map['created_by'] as String?) ?? '',
      isPublished: (map['is_published'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

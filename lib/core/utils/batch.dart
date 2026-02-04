class Batch {
  final String id;
  final String courseId;
  final String teacherId;
  final DateTime startDate;
  final DateTime endDate;
  final int seatLimit;
  final DateTime createdAt;

  const Batch({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.startDate,
    required this.endDate,
    required this.seatLimit,
    required this.createdAt,
  });

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      teacherId: map['teacher_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      seatLimit: (map['seat_limit'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

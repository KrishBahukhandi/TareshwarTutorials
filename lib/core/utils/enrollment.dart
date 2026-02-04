class Enrollment {
  final String id;
  final String studentId;
  final String batchId;
  final DateTime enrolledAt;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.batchId,
    required this.enrolledAt,
  });

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      batchId: map['batch_id'] as String,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
    );
  }
}

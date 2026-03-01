class RecordedVideo {
  final String id;
  final String batchId;
  final String title;
  final String videoUrl;
  final int durationSeconds;
  final String uploadedBy;
  final DateTime createdAt;
  // Optional denormalized fields for display
  final String? batchName;
  final String? courseName;

  const RecordedVideo({
    required this.id,
    required this.batchId,
    required this.title,
    required this.videoUrl,
    required this.durationSeconds,
    required this.uploadedBy,
    required this.createdAt,
    this.batchName,
    this.courseName,
  });

  factory RecordedVideo.fromMap(Map<String, dynamic> map) {
    final batch = map['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseTitle = course?['title'] as String?;
    final startDateStr = batch?['start_date'] as String?;
    String? batchLabel;
    if (startDateStr != null) {
      final d = DateTime.tryParse(startDateStr);
      if (d != null) batchLabel = '${d.day}/${d.month}/${d.year}';
    }

    return RecordedVideo(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      title: (map['title'] as String?) ?? '',
      videoUrl: (map['video_url'] as String?) ?? '',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      uploadedBy: (map['uploaded_by'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      batchName: batchLabel,
      courseName: courseTitle,
    );
  }
}

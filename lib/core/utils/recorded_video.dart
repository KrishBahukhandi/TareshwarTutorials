class RecordedVideo {
  final String id;
  final String batchId;
  final String title;
  final String videoUrl;
  final int durationSeconds;
  final String uploadedBy;
  final DateTime createdAt;

  const RecordedVideo({
    required this.id,
    required this.batchId,
    required this.title,
    required this.videoUrl,
    required this.durationSeconds,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory RecordedVideo.fromMap(Map<String, dynamic> map) {
    return RecordedVideo(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      title: (map['title'] as String?) ?? '',
      videoUrl: (map['video_url'] as String?) ?? '',
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      uploadedBy: (map['uploaded_by'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

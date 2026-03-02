class NoteItem {
  final String id;
  final String batchId;
  final String title;
  final String fileUrl;
  final String uploadedBy;
  final DateTime createdAt;
  // Optional denormalized fields for display
  final String? batchName;
  final String? courseName;

  const NoteItem({
    required this.id,
    required this.batchId,
    required this.title,
    required this.fileUrl,
    required this.uploadedBy,
    required this.createdAt,
    this.batchName,
    this.courseName,
  });

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    final batch = map['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseTitle = course?['title'] as String?;
    final startDateStr = batch?['start_date'] as String?;
    String? batchLabel;
    if (startDateStr != null) {
      final d = DateTime.tryParse(startDateStr);
      if (d != null) batchLabel = '${d.day}/${d.month}/${d.year}';
    }

    return NoteItem(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      title: (map['title'] as String?) ?? '',
      fileUrl: (map['file_url'] as String?) ?? '',
      uploadedBy: (map['uploaded_by'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      batchName: batchLabel,
      courseName: courseTitle,
    );
  }
}

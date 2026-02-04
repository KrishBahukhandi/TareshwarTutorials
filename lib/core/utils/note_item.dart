class NoteItem {
  final String id;
  final String batchId;
  final String title;
  final String fileUrl;
  final String uploadedBy;
  final DateTime createdAt;

  const NoteItem({
    required this.id,
    required this.batchId,
    required this.title,
    required this.fileUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      title: (map['title'] as String?) ?? '',
      fileUrl: (map['file_url'] as String?) ?? '',
      uploadedBy: (map['uploaded_by'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

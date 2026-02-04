import 'supabase_client.dart';

class AnalyticsService {
  Future<void> recordView({
    required String studentId,
    required String contentType,
    required String contentId,
  }) async {
    await supabase.from('content_views').insert({
      'student_id': studentId,
      'content_type': contentType,
      'content_id': contentId,
    });
  }
}

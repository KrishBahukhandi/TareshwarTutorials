import '../core/utils/enrollment.dart';
import 'supabase_client.dart';

class EnrollmentService {
  Future<void> enroll({
    required String studentId,
    required String batchId,
  }) async {
    await supabase.from('enrollments').insert({
      'student_id': studentId,
      'batch_id': batchId,
    });
  }

  Future<List<Enrollment>> fetchEnrollmentsForStudent(String studentId) async {
    final data = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', studentId)
        .order('enrolled_at', ascending: false);
    return data.map<Enrollment>((row) => Enrollment.fromMap(row)).toList();
  }

  Future<List<Enrollment>> fetchAll() async {
    final data = await supabase
        .from('enrollments')
        .select()
        .order('enrolled_at', ascending: false);
    return data.map<Enrollment>((row) => Enrollment.fromMap(row)).toList();
  }
}

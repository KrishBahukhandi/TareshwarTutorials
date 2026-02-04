import '../core/utils/batch.dart';
import '../core/utils/batch_with_course.dart';
import '../core/utils/course.dart';
import 'supabase_client.dart';

class BatchService {
  Future<void> createBatch({
    required String courseId,
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
    required int seatLimit,
  }) async {
    await supabase.from('batches').insert({
      'course_id': courseId,
      'teacher_id': teacherId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'seat_limit': seatLimit,
    });
  }

  Future<List<BatchWithCourse>> fetchBatchesForTeacher(String teacherId) async {
    final data = await supabase
        .from('batches')
        .select('id,course_id,teacher_id,start_date,end_date,seat_limit,created_at, courses:course_id (id,title,description,price,created_by,is_published,created_at)')
        .eq('teacher_id', teacherId)
        .order('start_date');

    return data.map<BatchWithCourse>((row) {
      final batch = Batch.fromMap(row);
      final course = Course.fromMap(row['courses'] as Map<String, dynamic>);
      return BatchWithCourse(batch: batch, course: course);
    }).toList();
  }

  Future<List<Batch>> fetchBatchesForCourse(String courseId) async {
    final data = await supabase
        .from('batches')
        .select()
        .eq('course_id', courseId)
        .order('start_date');
    return data.map<Batch>((row) => Batch.fromMap(row)).toList();
  }

  Future<List<Batch>> fetchAllBatches() async {
    final data = await supabase
        .from('batches')
        .select()
        .order('start_date', ascending: false);
    return data.map<Batch>((row) => Batch.fromMap(row)).toList();
  }
}

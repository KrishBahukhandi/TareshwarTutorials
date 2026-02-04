import '../core/utils/course.dart';
import 'supabase_client.dart';

class CourseService {
  Future<List<Course>> fetchAllCourses() async {
    final data = await supabase.from('courses').select().order('created_at');
    return data.map<Course>((row) => Course.fromMap(row)).toList();
  }

  Future<List<Course>> fetchPublishedCourses() async {
    final data = await supabase
        .from('courses')
        .select()
        .eq('is_published', true)
        .order('created_at');
    return data.map<Course>((row) => Course.fromMap(row)).toList();
  }

  Future<Course> fetchCourseById(String courseId) async {
    final data = await supabase
        .from('courses')
        .select()
        .eq('id', courseId)
        .single();
    return Course.fromMap(data);
  }

  Future<void> createCourse({
    required String title,
    required String description,
    required double price,
    required String createdBy,
  }) async {
    await supabase.from('courses').insert({
      'title': title,
      'description': description,
      'price': price,
      'created_by': createdBy,
      'is_published': false,
    });
  }

  Future<void> updateCourse({
    required String id,
    String? title,
    String? description,
    double? price,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;

    if (updates.isEmpty) return;

    await supabase.from('courses').update(updates).eq('id', id);
  }

  Future<void> setPublished({
    required String courseId,
    required bool isPublished,
  }) async {
    await supabase
        .from('courses')
        .update({'is_published': isPublished})
        .eq('id', courseId);
  }
}

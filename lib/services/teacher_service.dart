import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/teacher_profile.dart';
import 'supabase_client.dart';

class TeacherService {
  Future<List<TeacherProfile>> fetchTeachers() async {
    final profiles = await supabase
        .from('profiles')
        .select('id,name,email,role')
        .eq('role', 'teacher')
        .order('created_at', ascending: false);

    final teacherRows = await supabase
        .from('teachers')
        .select('id,is_active');

    final activeMap = {
      for (final row in teacherRows)
        row['id'] as String: (row['is_active'] as bool?) ?? true,
    };

    return profiles
        .map<TeacherProfile>((row) => TeacherProfile(
              id: row['id'] as String,
              name: (row['name'] as String?) ?? '',
              email: (row['email'] as String?) ?? '',
              isActive: activeMap[row['id'] as String] ?? true,
            ))
        .toList();
  }

  Future<void> createTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    // Create user in auth
    final response = await supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
      ),
    );

    final user = response.user;
    if (user == null) throw Exception('Failed to create user');

    // Create profile
    await supabase.from('profiles').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': 'teacher',
    });

    // Create teacher record
    await supabase.from('teachers').insert({
      'id': user.id,
      'is_active': true,
    });
  }

  Future<void> updateTeacher({
    required String id,
    String? name,
    String? email,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;

    if (updates.isEmpty) return;

    await supabase.from('profiles').update(updates).eq('id', id);
  }

  Future<void> deleteTeacher(String id) async {
    // Delete from teachers table first
    await supabase.from('teachers').delete().eq('id', id);
    // Delete user (will cascade delete profile)
    await supabase.auth.admin.deleteUser(id);
  }

  Future<void> setActive({
    required String teacherId,
    required bool isActive,
  }) async {
    await supabase.from('teachers').upsert({
      'id': teacherId,
      'is_active': isActive,
    });
  }

  /// Alias for setActive for consistency
  Future<void> toggleTeacherActive(String teacherId, bool isActive) async {
    return setActive(teacherId: teacherId, isActive: isActive);
  }

  Future<int> countTeachers() async {
    final response = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'teacher');
    
    return response.length;
  }

  Future<int> countActiveTeachers() async {
    final response = await supabase
        .from('teachers')
        .select('id')
        .eq('is_active', true);
    
    return response.length;
  }

  /// Get batches assigned to a specific teacher with course details
  Future<List<Map<String, dynamic>>> fetchTeacherBatches(String teacherId) async {
    final batches = await supabase
        .from('batches')
        .select('*, courses(*)')
        .eq('teacher_id', teacherId)
        .order('start_date', ascending: false);
    
    return batches;
  }

  /// Get total student count across all teacher's batches
  Future<int> fetchTeacherStudentCount(String teacherId) async {
    // Get all batches for this teacher
    final batches = await supabase
        .from('batches')
        .select('id')
        .eq('teacher_id', teacherId);
    
    if (batches.isEmpty) return 0;
    
    // Get all enrollments for these batches
    final batchIds = batches.map((b) => b['id'] as String).toList();
    
    final enrollments = await supabase
        .from('enrollments')
        .select('id')
        .inFilter('batch_id', batchIds)
        .eq('is_active', true);
    
    return enrollments.length;
  }

  /// Get students enrolled in a specific batch
  Future<List<Map<String, dynamic>>> fetchBatchStudents(String batchId) async {
    final enrollments = await supabase
        .from('enrollments')
        .select('student_id, enrolled_at, is_active')
        .eq('batch_id', batchId)
        .eq('is_active', true)
        .order('enrolled_at', ascending: false);
    
    if (enrollments.isEmpty) return [];
    
    // Get student profiles
    final studentIds = enrollments.map((e) => e['student_id'] as String).toList();
    
    final students = await supabase
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', studentIds);
    
    // Merge enrollment data with student data
    final result = <Map<String, dynamic>>[];
    for (final enrollment in enrollments) {
      final student = students.firstWhere(
        (s) => s['id'] == enrollment['student_id'],
        orElse: () => <String, dynamic>{},
      );
      
      if (student.isNotEmpty) {
        result.add({
          ...student,
          'enrolled_at': enrollment['enrolled_at'],
          'is_active': enrollment['is_active'],
        });
      }
    }
    
    return result;
  }
}

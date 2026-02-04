import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_user.dart';
import 'supabase_client.dart';

class StudentService {
  Future<List<AppUser>> fetchAllStudents() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('role', 'student')
        .order('created_at', ascending: false);
    
    return (data as List).map((item) => AppUser.fromMap(item)).toList();
  }

  Future<AppUser?> fetchStudentById(String id) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<void> createStudent({
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
      'role': 'student',
    });
  }

  Future<void> updateStudent({
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

  Future<void> deleteStudent(String id) async {
    // This will cascade delete the profile due to ON DELETE CASCADE
    await supabase.auth.admin.deleteUser(id);
  }

  Future<int> countStudents() async {
    final response = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'student');
    
    return response.length;
  }
}

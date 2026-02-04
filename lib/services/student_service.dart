import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_user.dart';
import 'audit_service.dart';
import 'supabase_client.dart';

class StudentService {
  final AuditService _auditService = AuditService();

  Future<List<AppUser>> fetchAllStudents({bool includeInactive = false}) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('role', 'student')
        .eq('is_active', includeInactive ? null : true)
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
      'is_active': true,
    });

    // Log the action
    await _auditService.logAction(
      action: 'create',
      resourceType: 'student',
      resourceId: user.id,
      resourceName: name,
      newData: {'name': name, 'email': email},
    );
  }

  /// Update student information
  Future<void> updateStudent({
    required String id,
    String? name,
    String? email,
    bool? isActive,
  }) async {
    // Fetch old data for audit log
    final oldStudent = await fetchStudentById(id);
    
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return;

    await supabase.from('profiles').update(updates).eq('id', id);

    // Log the action
    await _auditService.logAction(
      action: 'update',
      resourceType: 'student',
      resourceId: id,
      resourceName: oldStudent?.name ?? 'Unknown',
      oldData: oldStudent?.toMap(),
      newData: updates,
    );
  }

  /// Soft delete - sets is_active to false and deleted_at timestamp
  Future<void> softDeleteStudent(String id) async {
    final student = await fetchStudentById(id);
    
    await supabase.from('profiles').update({
      'is_active': false,
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    // Log the action
    await _auditService.logAction(
      action: 'delete',
      resourceType: 'student',
      resourceId: id,
      resourceName: student?.name ?? 'Unknown',
      oldData: student?.toMap(),
    );
  }

  /// Hard delete - permanently removes user (use with caution)
  Future<void> deleteStudent(String id) async {
    final student = await fetchStudentById(id);
    
    // This will cascade delete the profile due to ON DELETE CASCADE
    await supabase.auth.admin.deleteUser(id);

    // Log the action
    await _auditService.logAction(
      action: 'delete',
      resourceType: 'student',
      resourceId: id,
      resourceName: student?.name ?? 'Unknown',
      oldData: student?.toMap(),
    );
  }

  /// Restore a soft-deleted student
  Future<void> restoreStudent(String id) async {
    await supabase.from('profiles').update({
      'is_active': true,
      'deleted_at': null,
    }).eq('id', id);

    // Log the action
    await _auditService.logAction(
      action: 'activate',
      resourceType: 'student',
      resourceId: id,
    );
  }

  /// Toggle student active status
  Future<void> toggleStudentStatus(String id, bool isActive) async {
    await updateStudent(id: id, isActive: isActive);
    
    await _auditService.logAction(
      action: isActive ? 'activate' : 'deactivate',
      resourceType: 'student',
      resourceId: id,
    );
  }

  Future<int> countStudents() async {
    final response = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'student')
        .eq('is_active', true);
    
    return response.length;
  }
}

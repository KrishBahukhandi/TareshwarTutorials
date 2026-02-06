import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/student_service.dart';
import '../services/supabase_client.dart';

final studentServiceProvider = Provider((ref) => StudentService());

// Provider for student enrollments
final studentEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  
  return await ref.read(studentServiceProvider).fetchStudentEnrollments(user.id);
});

// Provider for student stats
final studentStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return {'enrolledCourses': 0, 'totalVideos': 0, 'totalNotes': 0};
  
  return await ref.read(studentServiceProvider).fetchStudentStats(user.id);
});

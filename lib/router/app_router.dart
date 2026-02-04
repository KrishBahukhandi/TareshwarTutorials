import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/batches/batches_list_screen.dart';
import '../admin/create_batch_screen.dart';
import '../admin/create_course_screen.dart';
import '../admin/dashboard_overview_screen.dart';
import '../admin/enrollments/enrollment_management_screen.dart';
import '../admin/manage_teachers_screen.dart';
import '../admin/students/create_student_screen.dart';
import '../admin/students/edit_student_screen.dart';
import '../admin/students/students_list_screen.dart';
import '../admin/teachers/create_teacher_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../student/course_detail_screen.dart';
import '../student/course_list_screen.dart';
import '../student/notes_list_screen.dart';
import '../student/student_dashboard.dart';
import '../student/video_list_screen.dart';
import '../student/video_player_screen.dart';
import '../teacher/teacher_content_list_screen.dart';
import '../teacher/teacher_courses_screen.dart';
import '../teacher/teacher_dashboard.dart';
import '../teacher/upload_notes_screen.dart';
import '../teacher/upload_video_screen.dart';
import '../services/supabase_client.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) => _redirect(state, authState),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const DashboardOverviewScreen(),
      ),
      // Students Management
      GoRoute(
        path: '/admin/students',
        builder: (context, state) => const StudentsListScreen(),
      ),
      GoRoute(
        path: '/admin/students/create',
        builder: (context, state) => const CreateStudentScreen(),
      ),
      GoRoute(
        path: '/admin/students/:id/edit',
        builder: (context, state) => EditStudentScreen(
          studentId: state.pathParameters['id']!,
        ),
      ),
      // Teachers Management
      GoRoute(
        path: '/admin/teachers',
        builder: (context, state) => const ManageTeachersScreen(),
      ),
      GoRoute(
        path: '/admin/teachers/create',
        builder: (context, state) => const CreateTeacherScreen(),
      ),
      // Courses Management
      GoRoute(
        path: '/admin/courses',
        builder: (context, state) => const CreateCourseScreen(),
      ),
      GoRoute(
        path: '/admin/courses/new',
        builder: (context, state) => const CreateCourseScreen(),
      ),
      // Batches Management
      GoRoute(
        path: '/admin/batches',
        builder: (context, state) => const BatchesListScreen(),
      ),
      GoRoute(
        path: '/admin/batches/new',
        builder: (context, state) => const CreateBatchScreen(),
      ),
      // Enrollment Management
      GoRoute(
        path: '/admin/enrollments',
        builder: (context, state) => const EnrollmentManagementScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/teacher/courses',
        builder: (context, state) => const TeacherCoursesScreen(),
      ),
      GoRoute(
        path: '/teacher/content',
        builder: (context, state) => const TeacherContentListScreen(),
      ),
      GoRoute(
        path: '/teacher/videos/upload',
        builder: (context, state) => const UploadVideoScreen(),
      ),
      GoRoute(
        path: '/teacher/notes/upload',
        builder: (context, state) => const UploadNotesScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/courses',
        builder: (context, state) => const CourseListScreen(),
      ),
      GoRoute(
        path: '/student/courses/:id',
        builder: (context, state) => CourseDetailScreen(
          courseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/student/videos',
        builder: (context, state) => const VideoListScreen(),
      ),
      GoRoute(
        path: '/student/videos/:id',
        builder: (context, state) => VideoPlayerScreen(
          videoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/student/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
    ],
  );
});

String? _redirect(GoRouterState state, AuthState authState) {
  final location = state.uri.toString();
  final isAuthRoute = location == '/login' || location == '/signup';

  final isLoading =
      authState.status == AuthStatus.initializing || authState.isLoading;
  if (isLoading) return null;

  final isAuthenticated = authState.status == AuthStatus.authenticated;
  if (!isAuthenticated) {
    return isAuthRoute ? null : '/login';
  }

  final role = authState.profile?.role ?? 'student';
  final roleLocation = _roleLocation(role);

  if (isAuthRoute) return roleLocation;

  final isAllowed = _isAllowedRoute(location, role);
  if (!isAllowed) return roleLocation;

  return null;
}

String _roleLocation(String role) {
  switch (role) {
    case 'admin':
      return '/admin';
    case 'teacher':
      return '/teacher';
    default:
      return '/student';
  }
}

bool _isAllowedRoute(String location, String role) {
  switch (role) {
    case 'admin':
      return location == '/admin' || location.startsWith('/admin/');
    case 'teacher':
      return location == '/teacher' || location.startsWith('/teacher/');
    case 'student':
      return location == '/student' || location.startsWith('/student/');
    default:
      return location == '/student' || location.startsWith('/student/');
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

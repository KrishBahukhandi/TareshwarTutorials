import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/utils/batch.dart';
import '../core/utils/batch_with_course.dart';
import '../core/utils/course.dart';
import '../core/utils/enrollment.dart';
import '../core/utils/teacher_profile.dart';
import '../services/batch_service.dart';
import '../services/course_service.dart';
import '../services/enrollment_service.dart';
import '../services/teacher_service.dart';

final teacherServiceProvider = Provider<TeacherService>((ref) => TeacherService());
final courseServiceProvider = Provider<CourseService>((ref) => CourseService());
final batchServiceProvider = Provider<BatchService>((ref) => BatchService());
final enrollmentServiceProvider = Provider<EnrollmentService>(
  (ref) => EnrollmentService(),
);

class TeachersController extends AsyncNotifier<List<TeacherProfile>> {
  @override
  Future<List<TeacherProfile>> build() async {
    return ref.read(teacherServiceProvider).fetchTeachers();
  }

  Future<void> toggleActive(TeacherProfile teacher, bool isActive) async {
    await ref
        .read(teacherServiceProvider)
        .setActive(teacherId: teacher.id, isActive: isActive);
    state = AsyncData([
      for (final t in state.value ?? [])
        if (t.id == teacher.id) t.copyWith(isActive: isActive) else t,
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(teacherServiceProvider).fetchTeachers());
  }
}

final teachersProvider =
    AsyncNotifierProvider<TeachersController, List<TeacherProfile>>(
  TeachersController.new,
);

class AdminCoursesController extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    return ref.read(courseServiceProvider).fetchAllCourses();
  }

  Future<void> createCourse({
    required String title,
    required String description,
    required double price,
    required String createdBy,
  }) async {
    await ref.read(courseServiceProvider).createCourse(
          title: title,
          description: description,
          price: price,
          createdBy: createdBy,
        );
    await refresh();
  }

  Future<void> setPublished(String courseId, bool isPublished) async {
    await ref.read(courseServiceProvider).setPublished(
          courseId: courseId,
          isPublished: isPublished,
        );
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(courseServiceProvider).fetchAllCourses());
  }
}

final adminCoursesProvider =
    AsyncNotifierProvider<AdminCoursesController, List<Course>>(
  AdminCoursesController.new,
);

class PublishedCoursesController extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    return ref.read(courseServiceProvider).fetchPublishedCourses();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state =
        AsyncData(await ref.read(courseServiceProvider).fetchPublishedCourses());
  }
}

final publishedCoursesProvider =
    AsyncNotifierProvider<PublishedCoursesController, List<Course>>(
  PublishedCoursesController.new,
);

final courseDetailProvider = FutureProvider.family<Course, String>((ref, id) {
  return ref.read(courseServiceProvider).fetchCourseById(id);
});

class TeacherBatchesController extends AsyncNotifier<List<BatchWithCourse>> {
  @override
  Future<List<BatchWithCourse>> build() async {
    final profile = ref.watch(profileProvider);
    if (profile == null) return [];
    return ref
        .read(batchServiceProvider)
        .fetchBatchesForTeacher(profile.id);
  }
}

final teacherBatchesProvider =
    AsyncNotifierProvider<TeacherBatchesController, List<BatchWithCourse>>(
  TeacherBatchesController.new,
);

final courseBatchesProvider = FutureProvider.family<List<Batch>, String>(
  (ref, courseId) =>
      ref.read(batchServiceProvider).fetchBatchesForCourse(courseId),
);

class EnrollmentsController extends AsyncNotifier<List<Enrollment>> {
  @override
  Future<List<Enrollment>> build() async {
    final profile = ref.watch(profileProvider);
    if (profile == null) return [];
    return ref
        .read(enrollmentServiceProvider)
        .fetchEnrollmentsForStudent(profile.id);
  }

  Future<void> enroll({
    required String studentId,
    required String batchId,
  }) async {
    await ref
        .read(enrollmentServiceProvider)
        .enroll(studentId: studentId, batchId: batchId);
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final profile = ref.read(profileProvider);
    if (profile == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(
      await ref
          .read(enrollmentServiceProvider)
          .fetchEnrollmentsForStudent(profile.id),
    );
  }
}

final enrollmentsProvider =
    AsyncNotifierProvider<EnrollmentsController, List<Enrollment>>(
  EnrollmentsController.new,
);

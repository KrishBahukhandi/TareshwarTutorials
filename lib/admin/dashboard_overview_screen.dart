import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/course_service.dart';
import '../services/student_service.dart';
import '../services/teacher_service.dart';
import '../services/batch_service.dart';
import '../services/enrollment_service.dart';
import 'widgets/admin_layout.dart';
import 'widgets/stat_card.dart';

// Providers for statistics
final studentCountProvider = FutureProvider<int>((ref) async {
  return await StudentService().countStudents();
});

final teacherCountProvider = FutureProvider<int>((ref) async {
  return await TeacherService().countTeachers();
});

final activeTeacherCountProvider = FutureProvider<int>((ref) async {
  return await TeacherService().countActiveTeachers();
});

final courseCountProvider = FutureProvider<int>((ref) async {
  final courses = await CourseService().fetchAllCourses();
  return courses.length;
});

final batchCountProvider = FutureProvider<int>((ref) async {
  final batches = await BatchService().fetchAllBatches();
  return batches.length;
});

final enrollmentCountProvider = FutureProvider<int>((ref) async {
  final enrollments = await EnrollmentService().fetchAll();
  return enrollments.length;
});

class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminLayout(
      currentRoute: '/admin',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Welcome back! Here\'s an overview of your platform.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200
                    ? 4
                    : constraints.maxWidth > 800
                        ? 3
                        : constraints.maxWidth > 500
                            ? 2
                            : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: [
                    // Students Card
                    ref.watch(studentCountProvider).when(
                          data: (count) => StatCard(
                            title: 'Total Students',
                            value: count.toString(),
                            icon: Icons.people_rounded,
                            color: const Color(0xFF3B82F6),
                            subtitle: 'Registered users',
                            onTap: () => context.go('/admin/students'),
                          ),
                          loading: () => const _LoadingCard(title: 'Total Students'),
                          error: (_, __) => const _ErrorCard(title: 'Total Students'),
                        ),

                    // Teachers Card
                    ref.watch(teacherCountProvider).when(
                          data: (count) {
                            final activeCount = ref.watch(activeTeacherCountProvider).value ?? 0;
                            return StatCard(
                              title: 'Total Teachers',
                              value: count.toString(),
                              icon: Icons.person_rounded,
                              color: const Color(0xFF10B981),
                              subtitle: '$activeCount active',
                              onTap: () => context.go('/admin/teachers'),
                            );
                          },
                          loading: () => const _LoadingCard(title: 'Total Teachers'),
                          error: (_, __) => const _ErrorCard(title: 'Total Teachers'),
                        ),

                    // Courses Card
                    ref.watch(courseCountProvider).when(
                          data: (count) => StatCard(
                            title: 'Total Courses',
                            value: count.toString(),
                            icon: Icons.book_rounded,
                            color: const Color(0xFF8B5CF6),
                            subtitle: 'Available courses',
                            onTap: () => context.go('/admin/courses'),
                          ),
                          loading: () => const _LoadingCard(title: 'Total Courses'),
                          error: (_, __) => const _ErrorCard(title: 'Total Courses'),
                        ),

                    // Batches Card
                    ref.watch(batchCountProvider).when(
                          data: (count) => StatCard(
                            title: 'Total Batches',
                            value: count.toString(),
                            icon: Icons.class_rounded,
                            color: const Color(0xFFF59E0B),
                            subtitle: 'Running batches',
                            onTap: () => context.go('/admin/batches'),
                          ),
                          loading: () => const _LoadingCard(title: 'Total Batches'),
                          error: (_, __) => const _ErrorCard(title: 'Total Batches'),
                        ),

                    // Enrollments Card
                    ref.watch(enrollmentCountProvider).when(
                          data: (count) => StatCard(
                            title: 'Total Enrollments',
                            value: count.toString(),
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF14B8A6),
                            subtitle: 'Active enrollments',
                            onTap: () => context.go('/admin/enrollments'),
                          ),
                          loading: () => const _LoadingCard(title: 'Total Enrollments'),
                          error: (_, __) => const _ErrorCard(title: 'Total Enrollments'),
                        ),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Add Teacher',
                  onTap: () => context.go('/admin/teachers/create'),
                ),
                _QuickActionButton(
                  icon: Icons.group_add_rounded,
                  label: 'Add Student',
                  onTap: () => context.go('/admin/students/create'),
                ),
                _QuickActionButton(
                  icon: Icons.add_rounded,
                  label: 'Create Course',
                  onTap: () => context.go('/admin/courses/new'),
                ),
                _QuickActionButton(
                  icon: Icons.class_rounded,
                  label: 'Create Batch',
                  onTap: () => context.go('/admin/batches/new'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            const Center(child: CircularProgressIndicator()),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            const Center(child: Icon(Icons.error_outline)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}

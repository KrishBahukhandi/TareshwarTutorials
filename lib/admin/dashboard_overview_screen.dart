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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Here\'s what\'s happening with your platform.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    // Students Card
                    ref.watch(studentCountProvider).when(
                          data: (count) => StatCard(
                            title: 'Total Students',
                            value: count.toString(),
                            icon: Icons.people,
                            color: Colors.blue,
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
                              icon: Icons.person,
                              color: Colors.green,
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
                            icon: Icons.book,
                            color: Colors.purple,
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
                            icon: Icons.class_,
                            color: Colors.orange,
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
                            icon: Icons.assignment,
                            color: Colors.teal,
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

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.person_add,
                  label: 'Add Teacher',
                  onTap: () => context.go('/admin/teachers/create'),
                ),
                _QuickActionButton(
                  icon: Icons.group_add,
                  label: 'Add Student',
                  onTap: () => context.go('/admin/students/create'),
                ),
                _QuickActionButton(
                  icon: Icons.add,
                  label: 'Create Course',
                  onTap: () => context.go('/admin/courses/new'),
                ),
                _QuickActionButton(
                  icon: Icons.class_,
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
    final theme = Theme.of(context);
    
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

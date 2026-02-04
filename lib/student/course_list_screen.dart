import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_providers.dart';

class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(publishedCoursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: courses.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No courses available yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final course = items[index];
              return Card(
                child: ListTile(
                  title: Text(course.title),
                  subtitle: Text(course.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/student/courses/${course.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

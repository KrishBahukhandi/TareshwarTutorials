import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/data_providers.dart';

class TeacherCoursesScreen extends ConsumerWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(teacherBatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Batches')),
      body: batches.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No assigned batches yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final batch = item.batch;
              final course = item.course;
              return Card(
                child: ListTile(
                  title: Text(course.title),
                  subtitle: Text(
                    'Batch: ${batch.startDate.toIso8601String().split('T').first} - '
                    '${batch.endDate.toIso8601String().split('T').first}',
                  ),
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

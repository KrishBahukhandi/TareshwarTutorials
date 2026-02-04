import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../providers/data_providers.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseDetailProvider(courseId));
    final batches = ref.watch(courseBatchesProvider(courseId));
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: course.when(
        data: (courseData) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(courseData.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(courseData.description),
              const SizedBox(height: 16),
              Text(
                'Batches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              batches.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No batches available yet.');
                  }
                  return Column(
                    children: [
                      for (final batch in items)
                        Card(
                          child: ListTile(
                            title: Text(
                              '${batch.startDate.toIso8601String().split('T').first} - '
                              '${batch.endDate.toIso8601String().split('T').first}',
                            ),
                            subtitle: Text('Seats: ${batch.seatLimit}'),
                            trailing: ElevatedButton(
                              onPressed: profile == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(enrollmentsProvider.notifier)
                                          .enroll(
                                            studentId: profile.id,
                                            batchId: batch.id,
                                          );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Enrollment requested.'),
                                        ),
                                      );
                                    },
                              child: const Text('Enroll'),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

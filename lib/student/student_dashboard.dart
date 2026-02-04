import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome, Student!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/student/courses'),
              child: const Text('Browse Courses'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/student/videos'),
              child: const Text('Recorded Lectures'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/student/notes'),
              child: const Text('Notes & PDFs'),
            ),
          ],
        ),
      ),
    );
  }
}

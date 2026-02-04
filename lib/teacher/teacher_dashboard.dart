import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
            const Text('Welcome, Teacher!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/teacher/courses'),
              child: const Text('View Assigned Batches'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/teacher/videos/upload'),
              child: const Text('Upload Recorded Video'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/teacher/notes/upload'),
              child: const Text('Upload Notes / PDF'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/teacher/content'),
              child: const Text('My Uploaded Content'),
            ),
          ],
        ),
      ),
    );
  }
}

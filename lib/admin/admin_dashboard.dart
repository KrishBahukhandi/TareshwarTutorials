import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            const Text('Welcome, Admin!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/admin/teachers'),
              child: const Text('Manage Teachers'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/admin/courses/new'),
              child: const Text('Create & Publish Courses'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/admin/batches/new'),
              child: const Text('Create Batches'),
            ),
          ],
        ),
      ),
    );
  }
}

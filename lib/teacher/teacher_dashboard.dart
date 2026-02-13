import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/teacher_service.dart';
import '../services/supabase_client.dart';
import 'widgets/teacher_layout.dart';

// Providers for teacher statistics
final teacherBatchesCountProvider = FutureProvider<int>((ref) async {
  final teacherId = supabase.auth.currentUser?.id;
  if (teacherId == null) return 0;
  
  final batches = await TeacherService().fetchTeacherBatches(teacherId);
  return batches.length;
});

final teacherStudentsCountProvider = FutureProvider<int>((ref) async {
  final teacherId = supabase.auth.currentUser?.id;
  if (teacherId == null) return 0;
  
  return await TeacherService().fetchTeacherStudentCount(teacherId);
});

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final user = ref.watch(authControllerProvider);

    return TeacherLayout(
      currentRoute: '/teacher',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Here\'s your teaching overview',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: AppTheme.gray600,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Statistics Cards
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate card width based on screen size
                double cardWidth;
                if (constraints.maxWidth < 600) {
                  cardWidth = constraints.maxWidth; // Full width on mobile
                } else if (constraints.maxWidth < 900) {
                  cardWidth = (constraints.maxWidth - 20) / 2; // 2 columns on tablet
                } else {
                  cardWidth = (constraints.maxWidth - 60) / 4; // 4 columns on desktop
                }

                return Wrap(
                  spacing: isMobile ? 12 : 20,
                  runSpacing: isMobile ? 12 : 20,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context: context,
                        title: 'My Batches',
                        provider: teacherBatchesCountProvider,
                        icon: Icons.class_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context: context,
                        title: 'Total Students',
                        provider: teacherStudentsCountProvider,
                        icon: Icons.people_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context: context,
                        title: 'Videos',
                        count: 0, // TODO: Implement content counts
                        icon: Icons.video_library_rounded,
                        color: AppTheme.warning,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context: context,
                        title: 'Notes',
                        count: 0, // TODO: Implement content counts
                        icon: Icons.note_rounded,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: isMobile ? 24 : 40),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 3.5 : 3,
              children: [
                _buildActionCard(
                  context: context,
                  title: 'Upload Video',
                  subtitle: 'Add a new video lecture',
                  icon: Icons.video_call_rounded,
                  color: AppTheme.success,
                  onTap: () => context.go('/teacher/videos/upload'),
                ),
                _buildActionCard(
                  context: context,
                  title: 'Upload Notes',
                  subtitle: 'Share study materials',
                  icon: Icons.upload_file_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: () => context.go('/teacher/notes/upload'),
                ),
                _buildActionCard(
                  context: context,
                  title: 'View Batches',
                  subtitle: 'Manage your classes',
                  icon: Icons.groups_rounded,
                  color: AppTheme.warning,
                  onTap: () => context.go('/teacher/courses'),
                ),
                _buildActionCard(
                  context: context,
                  title: 'My Content',
                  subtitle: 'View uploaded materials',
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.info,
                  onTap: () => context.go('/teacher/content'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    FutureProvider<int>? provider,
    int? count,
    required IconData icon,
    required Color color,
  }) {
    if (provider != null) {
      return Consumer(
        builder: (context, ref, _) {
          final value = ref.watch(provider);
          return value.when(
            data: (count) => _StatCard(
              title: title,
              value: count.toString(),
              icon: icon,
              color: color,
            ),
            loading: () => _StatCard(
              title: title,
              value: '...',
              icon: icon,
              color: color,
            ),
            error: (_, __) => _StatCard(
              title: title,
              value: '0',
              icon: icon,
              color: color,
            ),
          );
        },
      );
    }

    return _StatCard(
      title: title,
      value: count?.toString() ?? '0',
      icon: icon,
      color: color,
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

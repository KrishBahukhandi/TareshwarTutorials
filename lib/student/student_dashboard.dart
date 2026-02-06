import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../providers/student_providers.dart';
import 'widgets/student_layout.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isTablet = MediaQuery.of(context).size.width < 1200;
    final padding = isMobile ? 16.0 : 32.0;
    final stats = ref.watch(studentStatsProvider);
    final enrollments = ref.watch(studentEnrollmentsProvider);

    return StudentLayout(
      currentRoute: '/student',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Continue your learning journey',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.gray600,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Stats Cards
            stats.when(
              data: (data) => _buildStatsGrid(
                context,
                isMobile: isMobile,
                isTablet: isTablet,
                enrolledCourses: data['enrolledCourses'] ?? 0,
                totalVideos: data['totalVideos'] ?? 0,
                totalNotes: data['totalNotes'] ?? 0,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            SizedBox(height: isMobile ? 24 : 48),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context, isMobile: isMobile, isTablet: isTablet),
            
            SizedBox(height: isMobile ? 24 : 48),

            // Recent Enrollments
            enrollments.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyEnrollments(context, isMobile);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Enrolled Courses',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...items.take(3).map((enrollment) => _buildEnrollmentCard(
                      context,
                      enrollment,
                      isMobile,
                    )),
                    if (items.length > 3) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/student/my-courses'),
                          child: const Text('View All Courses →'),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required int enrolledCourses,
    required int totalVideos,
    required int totalNotes,
  }) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 3 : 2.5,
      children: [
        _buildStatCard(
          icon: Icons.book,
          label: 'Enrolled Courses',
          value: enrolledCourses.toString(),
          color: AppTheme.primaryBlue,
        ),
        _buildStatCard(
          icon: Icons.play_circle,
          label: 'Available Videos',
          value: totalVideos.toString(),
          color: AppTheme.success,
        ),
        _buildStatCard(
          icon: Icons.description,
          label: 'Available Notes',
          value: totalNotes.toString(),
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, {required bool isMobile, required bool isTablet}) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 3.5 : 3,
      children: [
        _buildActionCard(
          context,
          icon: Icons.explore,
          title: 'Browse Courses',
          subtitle: 'Discover new courses',
          color: AppTheme.primaryBlue,
          onTap: () => context.go('/student/courses'),
        ),
        _buildActionCard(
          context,
          icon: Icons.play_circle,
          title: 'Watch Videos',
          subtitle: 'Access recorded lectures',
          color: AppTheme.success,
          onTap: () => context.go('/student/videos'),
        ),
        _buildActionCard(
          context,
          icon: Icons.description,
          title: 'View Notes',
          subtitle: 'Download study materials',
          color: AppTheme.warning,
          onTap: () => context.go('/student/notes'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildEnrollmentCard(BuildContext context, Map<String, dynamic> enrollment, bool isMobile) {
    final batch = enrollment['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseName = course?['title'] ?? 'Unknown Course';
    final startDate = batch != null ? DateTime.parse(batch['start_date']) : null;
    final endDate = batch != null ? DateTime.parse(batch['end_date']) : null;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to course content for this enrollment
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.book,
                  color: AppTheme.primaryBlue,
                  size: isMobile ? 24 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (startDate != null && endDate != null)
                      Text(
                        '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
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

  Widget _buildEmptyEnrollments(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: isMobile ? 64 : 80,
            color: AppTheme.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Enrollments Yet',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse courses and enroll to start learning',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/student/courses'),
            icon: const Icon(Icons.explore),
            label: const Text('Browse Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

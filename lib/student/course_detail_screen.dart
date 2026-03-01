import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../providers/data_providers.dart';
import 'widgets/student_layout.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final course = ref.watch(courseDetailProvider(widget.courseId));
    final batches = ref.watch(courseBatchesProvider(widget.courseId));
    final profile = ref.watch(profileProvider);

    return StudentLayout(
      currentRoute: '/student/courses/${widget.courseId}',
      child: course.when(
        data: (courseData) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Header
                _buildCourseHeader(context, courseData, isMobile),
                SizedBox(height: isMobile ? 24 : 32),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.gray200),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: AppTheme.gray600,
                    indicatorColor: AppTheme.primaryBlue,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Available Batches'),
                    ],
                  ),
                ),

                // Tab Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview Tab
                      _buildOverviewTab(courseData, isMobile),

                      // Batches Tab
                      batches.when(
                        data: (items) => _buildBatchesTab(
                          context,
                          items,
                          profile,
                          isMobile,
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Center(
                          child: Text(
                            'Failed to load batches: $error',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load course: $error',
            style: TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context, dynamic courseData, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image
        Container(
          height: isMobile ? 180 : 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.8),
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.school,
              size: isMobile ? 80 : 120,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Course Title
        Text(
          courseData.title,
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(dynamic courseData, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Course',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            courseData.description,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.gray700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Course Features
          _buildFeatureItem(
            Icons.book_outlined,
            'Comprehensive Content',
            'Access to video lectures and study materials',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.play_circle_outline,
            'Video Lectures',
            'High-quality recorded video content',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.description_outlined,
            'Study Materials',
            'Downloadable notes and resources',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchesTab(
    BuildContext context,
    List items,
    dynamic profile,
    bool isMobile,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: AppTheme.gray400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Batches Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for upcoming batches',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildBatchCard(context, items[index], profile, isMobile);
      },
    );
  }

  Widget _buildBatchCard(
    BuildContext context,
    dynamic batch,
    dynamic profile,
    bool isMobile,
  ) {
    final startDate = batch.startDate;
    final endDate = batch.endDate;
    final isActive = startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
    final isClosed = endDate.isBefore(DateTime.now());

    Color statusColor;
    String statusLabel;
    
    if (isClosed) {
      statusColor = AppTheme.gray500;
      statusLabel = 'Closed';
    } else if (isActive) {
      statusColor = AppTheme.success;
      statusLabel = 'Active';
    } else {
      statusColor = AppTheme.warning;
      statusLabel = 'Upcoming';
    }

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
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Batch Info
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppTheme.gray600),
                const SizedBox(width: 8),
                Text(
                  'Start Date: ${startDate.day}/${startDate.month}/${startDate.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 18, color: AppTheme.gray600),
                const SizedBox(width: 8),
                Text(
                  'End Date: ${endDate.day}/${endDate.month}/${endDate.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 18, color: AppTheme.gray600),
                const SizedBox(width: 8),
                Text(
                  'Seats Available: ${batch.seatLimit}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enroll Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (profile == null || isClosed)
                    ? null
                    : () async {
                        await ref.read(enrollmentsProvider.notifier).enroll(
                              studentId: profile.id,
                              batchId: batch.id,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Enrollment request submitted!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.gray300,
                  disabledForegroundColor: AppTheme.gray600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isClosed ? 'Enrollment Closed' : 'Enroll Now',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

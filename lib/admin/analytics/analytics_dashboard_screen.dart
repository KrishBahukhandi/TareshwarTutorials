import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../services/batch_service.dart';
import '../../services/course_service.dart';
import '../../services/student_service.dart';
import '../../services/teacher_service.dart';
import '../widgets/admin_layout.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  
  // Metrics
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _totalTeachers = 0;
  int _activeTeachers = 0;
  int _totalCourses = 0;
  int _publishedCourses = 0;
  int _totalBatches = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        StudentService().fetchAllStudents(includeInactive: true),
        StudentService().fetchAllStudents(includeInactive: false),
        TeacherService().fetchTeachers(),
        CourseService().fetchAllCourses(),
        CourseService().fetchPublishedCourses(),
        BatchService().fetchAllBatches(),
      ]);

      setState(() {
        _totalStudents = (results[0] as List).length;
        _activeStudents = (results[1] as List).length;
        
        final teachers = results[2] as List;
        _totalTeachers = teachers.length;
        _activeTeachers = teachers.where((t) => t.isActive).length;
        
        _totalCourses = (results[3] as List).length;
        _publishedCourses = (results[4] as List).length;
        _totalBatches = (results[5] as List).length;
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/analytics',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platform performance and insights',
              style: TextStyle(fontSize: 14, color: AppTheme.gray600),
            ),
            const SizedBox(height: 32),

            // Loading State
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Key Metrics Row
              _buildMetricsGrid(),
              const SizedBox(height: 32),

              // Charts Section
              Text(
                'Trends & Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildChartsPlaceholder(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;
        final crossAxisCount = isWide ? 4 : 2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isWide ? 1.8 : 1.5,
          children: [
            _buildMetricCard(
              title: 'Total Students',
              value: _totalStudents.toString(),
              subtitle: '$_activeStudents active',
              icon: Icons.school,
              color: AppTheme.primaryBlue,
              trend: _activeStudents / (_totalStudents > 0 ? _totalStudents : 1),
            ),
            _buildMetricCard(
              title: 'Total Teachers',
              value: _totalTeachers.toString(),
              subtitle: '$_activeTeachers active',
              icon: Icons.person,
              color: AppTheme.success,
              trend: _activeTeachers / (_totalTeachers > 0 ? _totalTeachers : 1),
            ),
            _buildMetricCard(
              title: 'Total Courses',
              value: _totalCourses.toString(),
              subtitle: '$_publishedCourses published',
              icon: Icons.book,
              color: AppTheme.warning,
              trend: _publishedCourses / (_totalCourses > 0 ? _totalCourses : 1),
            ),
            _buildMetricCard(
              title: 'Total Batches',
              value: _totalBatches.toString(),
              subtitle: 'Running batches',
              icon: Icons.groups,
              color: AppTheme.info,
              trend: 1.0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double trend = 1.0,
  }) {
    final percentage = (trend * 100).toInt();
    
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                fontWeight: FontWeight.w600,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsPlaceholder() {
    return Column(
      children: [
        // Enrollment Overview
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.gray200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enrollment Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Visual charts will be added here',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gray200, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 48, color: AppTheme.gray400),
                        const SizedBox(height: 8),
                        Text(
                          'Chart Placeholder',
                          style: TextStyle(color: AppTheme.gray500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Install fl_chart package for visualizations',
                          style: TextStyle(fontSize: 12, color: AppTheme.gray400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Batch Occupancy
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.gray200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Occupancy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gray200),
                        ),
                        child: Center(
                          child: Icon(Icons.pie_chart, size: 40, color: AppTheme.gray400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.gray200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth Trends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gray200),
                        ),
                        child: Center(
                          child: Icon(Icons.show_chart, size: 40, color: AppTheme.gray400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

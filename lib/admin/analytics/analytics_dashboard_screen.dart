import 'package:fl_chart/fl_chart.dart';
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
  int _activeBatches = 0;

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

      final allBatches = results[5] as List;
      final now = DateTime.now();
      final activeBatchesCount = allBatches.where((batch) {
        return batch.startDate.isBefore(now) && batch.endDate.isAfter(now);
      }).length;

      setState(() {
        _totalStudents = (results[0] as List).length;
        _activeStudents = (results[1] as List).length;
        
        final teachers = results[2] as List;
        _totalTeachers = teachers.length;
        _activeTeachers = teachers.where((t) => t.isActive).length;
        
        _totalCourses = (results[3] as List).length;
        _publishedCourses = (results[4] as List).length;
        _totalBatches = allBatches.length;
        _activeBatches = activeBatchesCount;
        
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
                'Platform Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Row with two charts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUserDistributionChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildContentDistributionChart()),
                ],
              ),
              const SizedBox(height: 16),
              
              // Full width chart
              _buildBatchStatusChart(),
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
              subtitle: '$_activeBatches active',
              icon: Icons.groups,
              color: AppTheme.info,
              trend: _activeBatches / (_totalBatches > 0 ? _totalBatches : 1),
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

  Widget _buildUserDistributionChart() {
    return Card(
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
              'User Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: _activeStudents.toDouble(),
                      title: 'Students\n$_activeStudents',
                      color: AppTheme.primaryBlue,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _activeTeachers.toDouble(),
                      title: 'Teachers\n$_activeTeachers',
                      color: AppTheme.success,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDistributionChart() {
    return Card(
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
              'Content Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: _publishedCourses.toDouble(),
                      title: 'Courses\n$_publishedCourses',
                      color: AppTheme.warning,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _totalBatches.toDouble(),
                      title: 'Batches\n$_totalBatches',
                      color: AppTheme.info,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchStatusChart() {
    
    return Card(
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
              'Platform Activity Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [
                    _activeStudents.toDouble(),
                    _activeTeachers.toDouble(),
                    _publishedCourses.toDouble(),
                    _activeBatches.toDouble(),
                  ].reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Students', 'Teachers', 'Courses', 'Active\nBatches'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                titles[value.toInt()],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.gray600,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.gray600,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.gray200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: _activeStudents.toDouble(),
                          color: AppTheme.primaryBlue,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: _activeTeachers.toDouble(),
                          color: AppTheme.success,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: _publishedCourses.toDouble(),
                          color: AppTheme.warning,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: _activeBatches.toDouble(),
                          color: AppTheme.info,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

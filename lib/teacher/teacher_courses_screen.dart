import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/teacher_service.dart';
import '../services/supabase_client.dart';
import 'widgets/teacher_layout.dart';

// Provider for teacher's batches
final teacherBatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final teacherId = supabase.auth.currentUser?.id;
  if (teacherId == null) return [];
  
  return await TeacherService().fetchTeacherBatches(teacherId);
});

class TeacherCoursesScreen extends ConsumerStatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  ConsumerState<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends ConsumerState<TeacherCoursesScreen> {
  String _filterStatus = 'all'; // all, active, upcoming, past

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final batchesAsync = ref.watch(teacherBatchesProvider);

    return TeacherLayout(
      currentRoute: '/teacher/courses',
      child: batchesAsync.when(
        data: (batches) {
          final filteredBatches = _filterBatches(batches);

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'My Batches',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your teaching batches and students',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: AppTheme.gray600,
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 24),

                // Filter Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('All Batches', 'all', batches.length),
                    _buildFilterChip('Active', 'active', _countActive(batches)),
                    _buildFilterChip('Upcoming', 'upcoming', _countUpcoming(batches)),
                    _buildFilterChip('Past', 'past', _countPast(batches)),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 24),

                // Batches Grid
                if (filteredBatches.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.class_outlined,
                            size: 64,
                            color: AppTheme.gray300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyMessage(),
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount;
                      if (constraints.maxWidth < 600) {
                        crossAxisCount = 1;
                      } else if (constraints.maxWidth < 900) {
                        crossAxisCount = 2;
                      } else {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: filteredBatches.length,
                        itemBuilder: (context, index) {
                          return _buildBatchCard(filteredBatches[index]);
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load batches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.gray600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: isSelected ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.gray100,
      selectedColor: AppTheme.success.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.success,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.success : AppTheme.gray700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.success : AppTheme.gray200,
        width: 1,
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final course = batch['courses'] as Map<String, dynamic>?;
    final courseName = course?['title'] ?? 'Unknown Course';
    final startDate = DateTime.parse(batch['start_date'] as String);
    final endDate = DateTime.parse(batch['end_date'] as String);
    final seatLimit = batch['seat_limit'] as int? ?? 0;
    final batchId = batch['id'] as String;
    
    final status = _getBatchStatus(startDate, endDate);
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: InkWell(
        onTap: () => context.go('/teacher/batches/$batchId/detail'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),

              // Course Name
              Text(
                courseName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Date Range
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.gray500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Seat Limit
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: AppTheme.gray500),
                  const SizedBox(width: 6),
                  Text(
                    'Seats: $seatLimit',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // View Batch Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/teacher/batches/$batchId/detail'),
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Batch'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: AppTheme.success),
                    foregroundColor: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBatches(List<Map<String, dynamic>> batches) {
    if (_filterStatus == 'all') return batches;

    return batches.where((batch) {
      final startDate = DateTime.parse(batch['start_date'] as String);
      final endDate = DateTime.parse(batch['end_date'] as String);
      final status = _getBatchStatus(startDate, endDate);
      return status == _filterStatus;
    }).toList();
  }

  String _getBatchStatus(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 'past';
    if (now.isBefore(startDate)) return 'upcoming';
    return 'active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.success;
      case 'upcoming':
        return AppTheme.info;
      case 'past':
        return AppTheme.gray500;
      default:
        return AppTheme.gray500;
    }
  }

  int _countActive(List<Map<String, dynamic>> batches) {
    return batches.where((b) {
      final start = DateTime.parse(b['start_date'] as String);
      final end = DateTime.parse(b['end_date'] as String);
      return _getBatchStatus(start, end) == 'active';
    }).length;
  }

  int _countUpcoming(List<Map<String, dynamic>> batches) {
    return batches.where((b) {
      final start = DateTime.parse(b['start_date'] as String);
      final end = DateTime.parse(b['end_date'] as String);
      return _getBatchStatus(start, end) == 'upcoming';
    }).length;
  }

  int _countPast(List<Map<String, dynamic>> batches) {
    return batches.where((b) {
      final start = DateTime.parse(b['start_date'] as String);
      final end = DateTime.parse(b['end_date'] as String);
      return _getBatchStatus(start, end) == 'past';
    }).length;
  }

  String _getEmptyMessage() {
    switch (_filterStatus) {
      case 'active':
        return 'No active batches';
      case 'upcoming':
        return 'No upcoming batches';
      case 'past':
        return 'No past batches';
      default:
        return 'No batches assigned yet';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

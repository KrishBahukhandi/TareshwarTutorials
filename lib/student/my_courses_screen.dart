import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../providers/student_providers.dart';
import 'widgets/student_layout.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, active, completed

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isTablet = MediaQuery.of(context).size.width < 1200;
    final padding = isMobile ? 16.0 : 32.0;
    final enrollments = ref.watch(studentEnrollmentsProvider);

    return StudentLayout(
      currentRoute: '/student/my-courses',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'My Courses',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your enrolled courses and batches',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.gray600,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.gray400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ],
            ),
            
            if (isMobile) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ],

            SizedBox(height: isMobile ? 20 : 32),

            // Courses Grid
            enrollments.when(
              data: (items) {
                final filtered = _filterEnrollments(items);
                
                if (filtered.isEmpty) {
                  return _buildEmptyState(context, isMobile);
                }

                final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.2 : 1.1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(context, filtered[index], isMobile);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load courses: $error',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filter = value),
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.gray700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  List<Map<String, dynamic>> _filterEnrollments(List<Map<String, dynamic>> items) {
    var filtered = items;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((enrollment) {
        final batch = enrollment['batches'] as Map<String, dynamic>?;
        final course = batch?['courses'] as Map<String, dynamic>?;
        final courseName = course?['title']?.toString().toLowerCase() ?? '';
        return courseName.contains(_searchQuery);
      }).toList();
    }

    // Status filter
    if (_filter == 'active') {
      filtered = filtered.where((enrollment) {
        final batch = enrollment['batches'] as Map<String, dynamic>?;
        if (batch == null) return false;
        final endDate = DateTime.parse(batch['end_date']);
        return endDate.isAfter(DateTime.now());
      }).toList();
    } else if (_filter == 'completed') {
      filtered = filtered.where((enrollment) {
        final batch = enrollment['batches'] as Map<String, dynamic>?;
        if (batch == null) return false;
        final endDate = DateTime.parse(batch['end_date']);
        return endDate.isBefore(DateTime.now());
      }).toList();
    }

    return filtered;
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> enrollment, bool isMobile) {
    final batch = enrollment['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseName = course?['title'] ?? 'Unknown Course';
    final courseDescription = course?['description'] ?? 'No description';
    final startDate = batch != null ? DateTime.parse(batch['start_date']) : null;
    final endDate = batch != null ? DateTime.parse(batch['end_date']) : null;

    final batchId = batch?['id'] as String?;

    // Determine status
    final isActive = endDate != null && endDate.isAfter(DateTime.now());
    final statusColor = isActive ? AppTheme.success : AppTheme.gray500;
    final statusLabel = isActive ? 'Active' : 'Completed';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: InkWell(
        onTap: batchId == null ? null : () => context.go('/student/batch/$batchId'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image/Icon
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  Icons.book,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            
            // Course Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Course Name
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      courseDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Date Range
                    if (startDate != null && endDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppTheme.gray500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Widget _buildEmptyState(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: isMobile ? 64 : 80,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No Enrollments Yet' : 'No Courses Found',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Browse courses to get started'
                  : 'Try adjusting your search or filter',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

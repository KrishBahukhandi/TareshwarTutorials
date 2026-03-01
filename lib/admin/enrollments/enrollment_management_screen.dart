import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_user.dart';
import '../../core/utils/batch_with_course.dart';
import '../../services/batch_service.dart';
import '../../services/enrollment_service.dart';
import '../widgets/admin_layout.dart';

final batchesWithCourseProvider = FutureProvider<List<BatchWithCourse>>((ref) async {
  return await BatchService().fetchAllBatchesWithCourse();
});

class EnrollmentManagementScreen extends ConsumerStatefulWidget {
  const EnrollmentManagementScreen({super.key});

  @override
  ConsumerState<EnrollmentManagementScreen> createState() =>
      _EnrollmentManagementScreenState();
}

class _EnrollmentManagementScreenState
    extends ConsumerState<EnrollmentManagementScreen> {
  String? _selectedBatchId;
  bool _isLoading = false;
  List<dynamic> _enrollments = [];
  Map<String, dynamic>? _batchStats;

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/enrollments',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Enrollment Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage student enrollments in batches',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 32),

            // Batch Selector
            _buildBatchSelector(),
            const SizedBox(height: 24),

            // Stats Cards (if batch selected)
            if (_selectedBatchId != null && _batchStats != null)
              _buildStatsCards(),

            const SizedBox(height: 24),

            // Enrollments List or Empty State
            Expanded(
              child: _selectedBatchId == null
                  ? _buildEmptyState()
                  : _buildEnrollmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchSelector() {
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
            Row(
              children: [
                Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Batch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<BatchWithCourse>>(
              future: BatchService().fetchAllBatchesWithCourse(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final batches = snapshot.data ?? [];

                if (batches.isEmpty) {
                  return Text(
                    'No batches available. Create a batch first.',
                    style: TextStyle(color: AppTheme.gray600),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedBatchId,
                  decoration: const InputDecoration(
                    hintText: 'Choose a batch to manage enrollments',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  items: batches.map((bwc) {
                    final start = '${bwc.batch.startDate.day}/${bwc.batch.startDate.month}/${bwc.batch.startDate.year}';
                    final end = '${bwc.batch.endDate.day}/${bwc.batch.endDate.month}/${bwc.batch.endDate.year}';
                    return DropdownMenuItem<String>(
                      value: bwc.batch.id,
                      child: Text(
                        '${bwc.course.title} ($start – $end) · ${bwc.batch.seatLimit} seats',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBatchId = value);
                      _loadEnrollments(value);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _batchStats!;
    final enrolledCount = stats['enrolled_count'] as int;
    final seatLimit = stats['seat_limit'] as int;
    final availableSeats = stats['available_seats'] as int;
    final occupancy = stats['occupancy_percentage'] as int;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Seats',
            seatLimit.toString(),
            Icons.event_seat,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Enrolled',
            enrolledCount.toString(),
            Icons.people,
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Available',
            availableSeats.toString(),
            Icons.person_add,
            availableSeats > 0 ? AppTheme.warning : AppTheme.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Occupancy',
            '$occupancy%',
            Icons.analytics,
            occupancy >= 90
                ? AppTheme.error
                : occupancy >= 70
                    ? AppTheme.warning
                    : AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: AppTheme.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a batch to manage enrollments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a batch from the dropdown above',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Buttons
        Row(
          children: [
            FilledButton.icon(
              onPressed: _showAddStudentDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Enroll Student'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _enrollments.isEmpty ? null : _showBulkActions,
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Bulk Actions'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enrollments Table
        Expanded(
          child: _enrollments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 48, color: AppTheme.gray400),
                      const SizedBox(height: 16),
                      Text(
                        'No students enrolled yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.gray600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Enroll First Student'),
                      ),
                    ],
                  ),
                )
              : Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: ListView.separated(
                    itemCount: _enrollments.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final enrollment = _enrollments[index];
                      return _buildEnrollmentTile(enrollment);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentTile(dynamic enrollment) {
    final student = enrollment.student as AppUser;
    final enrollmentDate = enrollment.enrollment.enrolledAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        student.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.email),
          const SizedBox(height: 4),
          Text(
            'Enrolled: ${_formatDate(enrollmentDate)}',
            style: TextStyle(fontSize: 12, color: AppTheme.gray600),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Move to another batch',
            onPressed: () => _showMoveStudentDialog(student.id),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: AppTheme.error),
            tooltip: 'Remove from batch',
            onPressed: () => _confirmRemoveStudent(student.id, student.name),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEnrollments(String batchId) async {
    setState(() => _isLoading = true);

    try {
      final enrollments =
          await EnrollmentService().fetchEnrollmentsForBatch(batchId);
      final stats = await EnrollmentService().getBatchStats(batchId);

      setState(() {
        _enrollments = enrollments;
        _batchStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading enrollments: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddStudentDialog() async {
    if (_selectedBatchId == null) return;

    final unenrolledStudents =
        await EnrollmentService().getUnenrolledStudents(_selectedBatchId!);

    if (!mounted) return;

    if (unenrolledStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All students are already enrolled!')),
      );
      return;
    }

    final selectedStudent = await showDialog<AppUser>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll Student'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unenrolledStudents.length,
            itemBuilder: (context, index) {
              final student = unenrolledStudents[index];
              return ListTile(
                leading: CircleAvatar(child: Text(student.name[0].toUpperCase())),
                title: Text(student.name),
                subtitle: Text(student.email),
                onTap: () => Navigator.pop(context, student),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedStudent != null && mounted) {
      try {
        await EnrollmentService().enroll(
          studentId: selectedStudent.id,
          batchId: _selectedBatchId!,
        );
        _loadEnrollments(_selectedBatchId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedStudent.name} enrolled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmRemoveStudent(String studentId, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Remove $studentName from this batch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await EnrollmentService().unenroll(
          studentId: studentId,
          batchId: _selectedBatchId!,
        );
        _loadEnrollments(_selectedBatchId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student removed from batch'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showMoveStudentDialog(String studentId) async {
    // Get all batches except current one
    final allBatches = await BatchService().fetchAllBatchesWithCourse();
    final otherBatches =
        allBatches.where((b) => b.batch.id != _selectedBatchId).toList();

    if (!mounted) return;

    if (otherBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other batches available')),
      );
      return;
    }

    final selectedBatch = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Batch'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherBatches.length,
            itemBuilder: (context, index) {
              final bwc = otherBatches[index];
              final start = '${bwc.batch.startDate.day}/${bwc.batch.startDate.month}/${bwc.batch.startDate.year}';
              return ListTile(
                title: Text(bwc.course.title),
                subtitle: Text('From $start · ${bwc.batch.seatLimit} seats'),
                onTap: () => Navigator.pop(context, bwc.batch.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBatch != null && mounted) {
      try {
        await EnrollmentService().moveStudentBatch(
          studentId: studentId,
          fromBatchId: _selectedBatchId!,
          toBatchId: selectedBatch,
        );
        _loadEnrollments(_selectedBatchId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student moved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch ( e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showBulkActions() {
    // TODO: Implement bulk actions UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk actions coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

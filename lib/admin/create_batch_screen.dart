import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/course.dart';
import '../core/utils/teacher_profile.dart';
import '../providers/data_providers.dart';
import 'widgets/admin_layout.dart';

class CreateBatchScreen extends ConsumerStatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  ConsumerState<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends ConsumerState<CreateBatchScreen> {
  Course? _selectedCourse;
  TeacherProfile? _selectedTeacher;
  DateTime? _startDate;
  DateTime? _endDate;
  final _seatLimitController = TextEditingController(text: '30');

  @override
  void dispose() {
    _seatLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(adminCoursesProvider);
    final teachers = ref.watch(teachersProvider);

    return AdminLayout(
      currentRoute: '/admin/batches/new',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/admin/batches'),
                  ),
                  const SizedBox(width: 8),
                      Text(
                    'Create New Batch',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(
                  'Set up a new batch with course, teacher, and schedule',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray600,
                      ),
                ),
              ),
              const SizedBox(height: 32),

              // Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
              courses.when(
                data: (items) => DropdownButtonFormField<Course>(
                  initialValue: _selectedCourse,
                  items: items
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course.title),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCourse = value),
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 12),
              teachers.when(
                data: (items) {
                  final activeTeachers =
                      items.where((teacher) => teacher.isActive).toList();
                  if (activeTeachers.isEmpty) {
                    return const Text('No active teachers available.');
                  }
                  return DropdownButtonFormField<TeacherProfile>(
                    initialValue: _selectedTeacher,
                    items: activeTeachers
                        .map((teacher) => DropdownMenuItem(
                              value: teacher,
                              child: Text(
                                teacher.name.isEmpty
                                    ? teacher.email
                                    : teacher.name,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTeacher = value),
                    decoration: const InputDecoration(labelText: 'Teacher'),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _seatLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seat limit'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: _startDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Text(
                        _startDate == null
                            ? 'Start date'
                            : _startDate!.toIso8601String().split('T').first,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: _endDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      child: Text(
                        _endDate == null
                            ? 'End date'
                            : _endDate!.toIso8601String().split('T').first,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final course = _selectedCourse;
                    final teacher = _selectedTeacher;
                    final start = _startDate;
                    final end = _endDate;
                    final seatLimit =
                        int.tryParse(_seatLimitController.text.trim());

                    if (course == null ||
                        teacher == null ||
                        start == null ||
                        end == null ||
                        seatLimit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill all fields.')),
                      );
                      return;
                    }

                    await ref.read(batchServiceProvider).createBatch(
                          courseId: course.id,
                          teacherId: teacher.id,
                          startDate: start,
                          endDate: end,
                          seatLimit: seatLimit,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Batch created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.go('/admin/batches');
                    }
                  },
                  child: const Text('Create Batch'),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/batch_service.dart';
import '../../services/course_service.dart';
import '../../services/teacher_service.dart';
import '../widgets/admin_layout.dart';

class EditBatchScreen extends StatefulWidget {
  final String batchId;

  const EditBatchScreen({
    super.key,
    required this.batchId,
  });

  @override
  State<EditBatchScreen> createState() => _EditBatchScreenState();
}

class _EditBatchScreenState extends State<EditBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seatLimitController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  String? _selectedCourseId;
  String? _selectedTeacherId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  List<Map<String, String>> _courses = [];
  List<Map<String, String>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _seatLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load batch data
      final batch = await BatchService().fetchBatchById(widget.batchId);
      
      // Load courses and teachers
      final courses = await CourseService().fetchAllCourses();
      final teachers = await TeacherService().fetchTeachers();
      
      setState(() {
        _selectedCourseId = batch.courseId;
        _selectedTeacherId = batch.teacherId;
        _startDate = batch.startDate;
        _endDate = batch.endDate;
        _seatLimitController.text = batch.seatLimit.toString();
        
        _courses = courses.map((c) => {'id': c.id, 'title': c.title}).toList();
        _teachers = teachers.map((t) => {'id': t.id, 'name': t.name}).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load batch: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select course and teacher'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await BatchService().updateBatch(
        id: widget.batchId,
        courseId: _selectedCourseId,
        teacherId: _selectedTeacherId,
        startDate: _startDate,
        endDate: _endDate,
        seatLimit: int.parse(_seatLimitController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/admin/batches');
      }
    } catch (e) {
      setState(() => _isSaving = false);
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

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/batches',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  'Edit Batch',
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
                'Update batch details and schedule',
                style: TextStyle(fontSize: 14, color: AppTheme.gray600),
              ),
            ),
            const SizedBox(height: 32),

            // Form Card
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: TextStyle(color: AppTheme.error)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course Selector
                          Text(
                            'Course',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            decoration: const InputDecoration(
                              hintText: 'Select course',
                              prefixIcon: Icon(Icons.book, size: 20),
                            ),
                            items: _courses.map((course) {
                              return DropdownMenuItem(
                                value: course['id'],
                                child: Text(course['title']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCourseId = value);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Teacher Selector
                          Text(
                            'Teacher',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedTeacherId,
                            decoration: const InputDecoration(
                              hintText: 'Select teacher',
                              prefixIcon: Icon(Icons.person, size: 20),
                            ),
                            items: _teachers.map((teacher) {
                              return DropdownMenuItem(
                                value: teacher['id'],
                                child: Text(teacher['name']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedTeacherId = value);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Date Range
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.gray700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _selectDate(true),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.gray300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 20, color: AppTheme.gray600),
                                            const SizedBox(width: 12),
                                            Text(
                                              _startDate != null
                                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                                  : 'Select date',
                                              style: TextStyle(
                                                color: _startDate != null ? AppTheme.gray900 : AppTheme.gray500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.gray700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _selectDate(false),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.gray300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 20, color: AppTheme.gray600),
                                            const SizedBox(width: 12),
                                            Text(
                                              _endDate != null
                                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                  : 'Select date',
                                              style: TextStyle(
                                                color: _endDate != null ? AppTheme.gray900 : AppTheme.gray500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Seat Limit
                          Text(
                            'Seat Limit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _seatLimitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter seat limit',
                              prefixIcon: Icon(Icons.people, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Seat limit is required';
                              }
                              final limit = int.tryParse(value);
                              if (limit == null || limit < 1) {
                                return 'Enter a valid seat limit';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => context.go('/admin/batches'),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _saveChanges,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

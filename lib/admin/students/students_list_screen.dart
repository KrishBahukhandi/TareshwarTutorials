import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_user.dart';
import '../../services/student_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/search_filter_widgets.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  List<AppUser> _allStudents = [];
  List<AppUser> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await StudentService().fetchAllStudents();
      setState(() {
        _allStudents = students;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    var filtered = _allStudents;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        final query = _searchQuery.toLowerCase();
        return student.name.toLowerCase().contains(query) ||
            student.email.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter == 'active') {
      filtered = filtered.where((s) => s.isActive == true).toList();
    } else if (_selectedFilter == 'inactive') {
      filtered = filtered.where((s) => s.isActive == false).toList();
    }

    setState(() {
      _filteredStudents = filtered;
      _currentPage = 1; // Reset to first page
    });
  }

  List<AppUser> get _paginatedStudents {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= _filteredStudents.length) return [];
    return _filteredStudents.sublist(
      start,
      end > _filteredStudents.length ? _filteredStudents.length : end,
    );
  }

  int get _totalPages {
    return (_filteredStudents.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/students',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    if (isMobile) {
                      // Stack vertically on mobile
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Students Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/students/create'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Student'),
                          ),
                        ],
                      );
                    } else {
                      // Row layout on tablet/desktop
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Students Management',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/students/create'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Student'),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredStudents.length} student${_filteredStudents.length != 1 ? 's' : ''} found',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
                const SizedBox(height: 24),

                // Search and Filters
                AdminSearchFilters(
                  searchHint: 'Search by name or email...',
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                    _applyFilters();
                  },
                  searchValue: _searchQuery,
                  filters: [
                    FilterOption(
                      label: 'All Students',
                      value: 'all',
                      icon: Icons.people,
                      color: AppTheme.primaryBlue,
                    ),
                    FilterOption(
                      label: 'Active',
                      value: 'active',
                      icon: Icons.check_circle,
                      color: AppTheme.success,
                    ),
                    FilterOption(
                      label: 'Inactive',
                      value: 'inactive',
                      icon: Icons.cancel,
                      color: AppTheme.error,
                    ),
                  ],
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          // Students list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? AdminEmptyState(
                        title: _searchQuery.isEmpty
                            ? 'No students yet'
                            : 'No students found',
                        message: _searchQuery.isEmpty
                            ? 'Add your first student to get started'
                            : 'Try adjusting your search or filters',
                        icon: Icons.people_outline,
                        onAction: _searchQuery.isEmpty
                            ? () => context.go('/admin/students/create')
                            : null,
                        actionLabel: _searchQuery.isEmpty ? 'Add Student' : null,
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.gray200),
                              ),
                              child: ListView.separated(
                                itemCount: _paginatedStudents.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final student = _paginatedStudents[index];
                                  return _buildStudentTile(student);
                                },
                              ),
                            ),
                          ),

                          // Pagination
                          if (_totalPages > 1)
                            AdminPagination(
                              currentPage: _currentPage,
                              totalPages: _totalPages,
                              itemsPerPage: _itemsPerPage,
                              totalItems: _filteredStudents.length,
                              onPageChanged: (page) {
                                setState(() => _currentPage = page);
                              },
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(AppUser student) {
    final isActive = student.isActive ?? true;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isActive
            ? AppTheme.primaryBlue.withOpacity(0.1)
            : AppTheme.gray300,
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
          style: TextStyle(
            color: isActive ? AppTheme.primaryBlue : AppTheme.gray600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            student.name.isEmpty ? 'Unnamed' : student.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (!isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(student.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => context.go('/admin/students/${student.id}/edit'),
            tooltip: 'Edit student',
            color: AppTheme.gray700,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
            onPressed: () => _confirmDeleteStudent(student.id, student.name),
            tooltip: 'Delete student',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteStudent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await StudentService().softDeleteStudent(id);
        _loadStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted successfully'),
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
}

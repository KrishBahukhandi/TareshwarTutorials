import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/teacher_profile.dart';
import '../services/teacher_service.dart';
import 'widgets/admin_layout.dart';
import 'widgets/search_filter_widgets.dart';

class ManageTeachersScreen extends ConsumerStatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  ConsumerState<ManageTeachersScreen> createState() =>
      _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends ConsumerState<ManageTeachersScreen> {
  List<TeacherProfile> _allTeachers = [];
  List<TeacherProfile> _filteredTeachers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await TeacherService().fetchTeachers();
      setState(() {
        _allTeachers = teachers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teachers: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    var filtered = _allTeachers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((teacher) {
        final query = _searchQuery.toLowerCase();
        return teacher.name.toLowerCase().contains(query) ||
            teacher.email.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter == 'active') {
      filtered = filtered.where((t) => t.isActive).toList();
    } else if (_selectedFilter == 'inactive') {
      filtered = filtered.where((t) => !t.isActive).toList();
    }

    setState(() {
      _filteredTeachers = filtered;
      _currentPage = 1; // Reset to first page
    });
  }

  List<TeacherProfile> get _paginatedTeachers {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= _filteredTeachers.length) return [];
    return _filteredTeachers.sublist(
      start,
      end > _filteredTeachers.length ? _filteredTeachers.length : end,
    );
  }

  int get _totalPages {
    return (_filteredTeachers.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/teachers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Teachers Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/teachers/create'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Teacher'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredTeachers.length} teacher${_filteredTeachers.length != 1 ? 's' : ''} found',
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
                      label: 'All Teachers',
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

          // Teachers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTeachers.isEmpty
                    ? AdminEmptyState(
                        title: _searchQuery.isEmpty
                            ? 'No teachers yet'
                            : 'No teachers found',
                        message: _searchQuery.isEmpty
                            ? 'Add your first teacher to get started'
                            : 'Try adjusting your search or filters',
                        icon: Icons.person_outline,
                        onAction: _searchQuery.isEmpty
                            ? () => context.go('/admin/teachers/create')
                            : null,
                        actionLabel: _searchQuery.isEmpty ? 'Add Teacher' : null,
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
                                itemCount: _paginatedTeachers.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final teacher = _paginatedTeachers[index];
                                  return _buildTeacherTile(teacher);
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
                              totalItems: _filteredTeachers.length,
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

  Widget _buildTeacherTile(TeacherProfile teacher) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: teacher.isActive
            ? AppTheme.primaryBlue.withOpacity(0.1)
            : AppTheme.gray300,
        child: Icon(
          Icons.person,
          color: teacher.isActive ? AppTheme.primaryBlue : AppTheme.gray600,
        ),
      ),
      title: Row(
        children: [
          Text(
            teacher.name.isEmpty ? 'Unnamed' : teacher.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (!teacher.isActive)
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
      subtitle: Text(teacher.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle active/inactive
          IconButton(
            icon: Icon(
              teacher.isActive ? Icons.toggle_on : Icons.toggle_off,
              color: teacher.isActive ? AppTheme.success : AppTheme.gray400,
            ),
            tooltip: teacher.isActive ? 'Deactivate' : 'Activate',
            onPressed: () => _toggleTeacherStatus(teacher),
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
            onPressed: () => _confirmDeleteTeacher(teacher.id, teacher.name),
            tooltip: 'Delete teacher',
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTeacherStatus(TeacherProfile teacher) async {
    try {
      await TeacherService().toggleTeacherActive(teacher.id, !teacher.isActive);
      _loadTeachers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Teacher ${teacher.isActive ? "deactivated" : "activated"} successfully',
            ),
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

  Future<void> _confirmDeleteTeacher(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
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
        await TeacherService().deleteTeacher(id);
        _loadTeachers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher deleted successfully'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/course.dart';
import '../../services/course_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/search_filter_widgets.dart';

class CoursesListScreen extends ConsumerStatefulWidget {
  const CoursesListScreen({super.key});

  @override
  ConsumerState<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends ConsumerState<CoursesListScreen> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await CourseService().fetchAllCourses();
      setState(() {
        _allCourses = courses;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    var filtered = _allCourses;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) {
        final query = _searchQuery.toLowerCase();
        return course.title.toLowerCase().contains(query) ||
            course.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter == 'published') {
      filtered = filtered.where((c) => c.isPublished).toList();
    } else if (_selectedFilter == 'draft') {
      filtered = filtered.where((c) => !c.isPublished).toList();
    }

    setState(() {
      _filteredCourses = filtered;
      _currentPage = 1; // Reset to first page
    });
  }

  List<Course> get _paginatedCourses {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= _filteredCourses.length) return [];
    return _filteredCourses.sublist(
      start,
      end > _filteredCourses.length ? _filteredCourses.length : end,
    );
  }

  int get _totalPages {
    return (_filteredCourses.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/courses',
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
                            'Courses Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/courses/new'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Course'),
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
                              'Courses Management',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/courses/new'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Course'),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredCourses.length} course${_filteredCourses.length != 1 ? 's' : ''} found',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
                const SizedBox(height: 24),

                // Search and Filters
                AdminSearchFilters(
                  searchHint: 'Search by title or description...',
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                    _applyFilters();
                  },
                  searchValue: _searchQuery,
                  filters: [
                    FilterOption(
                      label: 'All Courses',
                      value: 'all',
                      icon: Icons.book,
                      color: AppTheme.primaryBlue,
                    ),
                    FilterOption(
                      label: 'Published',
                      value: 'published',
                      icon: Icons.public,
                      color: AppTheme.success,
                    ),
                    FilterOption(
                      label: 'Draft',
                      value: 'draft',
                      icon: Icons.public_off,
                      color: AppTheme.warning,
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

          // Courses list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? AdminEmptyState(
                        title: _searchQuery.isEmpty
                            ? 'No courses yet'
                            : 'No courses found',
                        message: _searchQuery.isEmpty
                            ? 'Add your first course to get started'
                            : 'Try adjusting your search or filters',
                        icon: Icons.book_outlined,
                        onAction: _searchQuery.isEmpty
                            ? () => context.go('/admin/courses/new')
                            : null,
                        actionLabel: _searchQuery.isEmpty ? 'Add Course' : null,
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
                                itemCount: _paginatedCourses.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final course = _paginatedCourses[index];
                                  return _buildCourseTile(course);
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
                              totalItems: _filteredCourses.length,
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

  Widget _buildCourseTile(Course course) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.book, color: AppTheme.primaryBlue),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              course.title.isEmpty ? 'Untitled' : course.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: course.isPublished
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  course.isPublished ? Icons.public : Icons.public_off,
                  size: 12,
                  color: course.isPublished ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  course.isPublished ? 'Published' : 'Draft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: course.isPublished ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            course.description.isEmpty ? 'No description' : course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppTheme.gray600),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${course.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => context.go('/admin/courses/${course.id}/edit'),
            tooltip: 'Edit course',
            color: AppTheme.gray700,
          ),
          // Toggle published
          IconButton(
            icon: Icon(
              course.isPublished ? Icons.visibility : Icons.visibility_off,
              color: course.isPublished ? AppTheme.success : AppTheme.gray400,
            ),
            tooltip: course.isPublished ? 'Unpublish' : 'Publish',
            onPressed: () => _togglePublished(course),
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
            tooltip: 'Delete course',
            onPressed: () => _confirmDelete(course),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Delete "${course.title}"? This cannot be undone and will also remove all associated batches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await CourseService().deleteCourse(course.id);
        _loadCourses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _togglePublished(Course course) async {
    try {
      await CourseService().setPublished(
        courseId: course.id,
        isPublished: !course.isPublished,
      );
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course ${course.isPublished ? "unpublished" : "published"} successfully',
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
}

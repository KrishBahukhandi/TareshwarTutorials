import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/batch_with_course.dart';
import '../../services/batch_service.dart';
import '../widgets/admin_layout.dart';
import '../widgets/search_filter_widgets.dart';

class BatchesListScreen extends ConsumerStatefulWidget {
  const BatchesListScreen({super.key});

  @override
  ConsumerState<BatchesListScreen> createState() => _BatchesListScreenState();
}

class _BatchesListScreenState extends ConsumerState<BatchesListScreen> {
  List<BatchWithCourse> _allBatches = [];
  List<BatchWithCourse> _filteredBatches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final batches = await BatchService().fetchAllBatchesWithCourse();
      setState(() {
        _allBatches = batches;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading batches: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isBatchActive(BatchWithCourse bwc) {
    final now = DateTime.now();
    return bwc.batch.startDate.isBefore(now) && bwc.batch.endDate.isAfter(now);
  }

  void _applyFilters() {
    var filtered = _allBatches;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((bwc) {
        final query = _searchQuery.toLowerCase();
        return bwc.course.title.toLowerCase().contains(query) ||
            bwc.batch.id.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter == 'active') {
      filtered = filtered.where((b) => _isBatchActive(b)).toList();
    } else if (_selectedFilter == 'upcoming') {
      filtered = filtered.where((b) => b.batch.startDate.isAfter(DateTime.now())).toList();
    } else if (_selectedFilter == 'past') {
      filtered = filtered.where((b) => b.batch.endDate.isBefore(DateTime.now())).toList();
    }

    setState(() {
      _filteredBatches = filtered;
      _currentPage = 1;
    });
  }

  List<BatchWithCourse> get _paginatedBatches {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= _filteredBatches.length) return [];
    return _filteredBatches.sublist(
      start,
      end > _filteredBatches.length ? _filteredBatches.length : end,
    );
  }

  int get _totalPages {
    return (_filteredBatches.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/batches',
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
                            'Batches Management',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/batches/new'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Batch'),
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
                              'Batches Management',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/admin/batches/new'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Batch'),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredBatches.length} batch${_filteredBatches.length != 1 ? 'es' : ''} found',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                ),
                const SizedBox(height: 24),

                // Search and Filters
                AdminSearchFilters(
                  searchHint: 'Search by course name...',
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                    _applyFilters();
                  },
                  searchValue: _searchQuery,
                  filters: [
                    FilterOption(
                      label: 'All Batches',
                      value: 'all',
                      icon: Icons.groups,
                      color: AppTheme.primaryBlue,
                    ),
                    FilterOption(
                      label: 'Active',
                      value: 'active',
                      icon: Icons.play_circle,
                      color: AppTheme.success,
                    ),
                    FilterOption(
                      label: 'Upcoming',
                      value: 'upcoming',
                      icon: Icons.schedule,
                      color: AppTheme.info,
                    ),
                    FilterOption(
                      label: 'Past',
                      value: 'past',
                      icon: Icons.history,
                      color: AppTheme.gray500,
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

          // Batches list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBatches.isEmpty
                    ? AdminEmptyState(
                        title: _searchQuery.isEmpty
                            ? 'No batches yet'
                            : 'No batches found',
                        message: _searchQuery.isEmpty
                            ? 'Create your first batch to get started'
                            : 'Try adjusting your search or filters',
                        icon: Icons.groups_outlined,
                        onAction: _searchQuery.isEmpty
                            ? () => context.go('/admin/batches/new')
                            : null,
                        actionLabel: _searchQuery.isEmpty ? 'Add Batch' : null,
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
                                itemCount: _paginatedBatches.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final bwc = _paginatedBatches[index];
                                  return _buildBatchTile(bwc);
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
                              totalItems: _filteredBatches.length,
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

  Widget _buildBatchTile(BatchWithCourse bwc) {
    final batch = bwc.batch;
    final course = bwc.course;
    final isActive = _isBatchActive(bwc);
    final isUpcoming = batch.startDate.isAfter(DateTime.now());
    final startDate = '${batch.startDate.day}/${batch.startDate.month}/${batch.startDate.year}';
    final endDate = '${batch.endDate.day}/${batch.endDate.month}/${batch.endDate.year}';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = AppTheme.success;
      statusText = 'Active';
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = AppTheme.info;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    } else {
      statusColor = AppTheme.gray500;
      statusText = 'Past';
      statusIcon = Icons.history;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.groups, color: statusColor),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              course.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppTheme.gray600),
              const SizedBox(width: 6),
              Text(
                '$startDate → $endDate',
                style: TextStyle(fontSize: 13, color: AppTheme.gray600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event_seat, size: 14, color: AppTheme.gray600),
              const SizedBox(width: 6),
              Text(
                '${batch.seatLimit} seats',
                style: TextStyle(fontSize: 13, color: AppTheme.gray600),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => context.go('/admin/batches/${batch.id}/edit'),
        tooltip: 'Edit batch',
        color: AppTheme.gray700,
      ),
    );
  }
}

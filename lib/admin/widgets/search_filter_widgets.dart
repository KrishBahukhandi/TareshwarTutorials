import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Reusable search bar widget for admin screens
class AdminSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearch;
  final String? initialValue;
  final IconData? prefixIcon;

  const AdminSearchBar({
    super.key,
    required this.hintText,
    required this.onSearch,
    this.initialValue,
    this.prefixIcon,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onSearch,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon ?? Icons.search,
          size: 20,
          color: AppTheme.gray600,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20, color: AppTheme.gray600),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Filter chip widget for status filters
class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppTheme.primaryBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppTheme.gray300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppTheme.gray600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppTheme.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pagination controls widget
class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > totalItems)
        ? totalItems
        : currentPage * itemsPerPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        border: Border(top: BorderSide(color: AppTheme.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            'Showing $startItem-$endItem of $totalItems',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray700,
            ),
          ),

          // Page controls
          Row(
            children: [
              // Items per page selector
              if (onItemsPerPageChanged != null) ...[
                Text(
                  'Rows per page:',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray700),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  items: [10, 25, 50, 100].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onItemsPerPageChanged!(value);
                  },
                ),
                const SizedBox(width: 24),
              ],

              // Previous button
              IconButton(
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                color: AppTheme.gray700,
                disabledColor: AppTheme.gray400,
              ),

              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ),

              // Next button
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                color: AppTheme.gray700,
                disabledColor: AppTheme.gray400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Combined search and filter bar
class AdminSearchFilters extends StatelessWidget {
  final String searchHint;
  final Function(String) onSearch;
  final List<FilterOption> filters;
  final String? selectedFilter;
  final Function(String) onFilterChanged;
  final String? searchValue;

  const AdminSearchFilters({
    super.key,
    required this.searchHint,
    required this.onSearch,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.searchValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        AdminSearchBar(
          hintText: searchHint,
          onSearch: onSearch,
          initialValue: searchValue,
        ),
        const SizedBox(height: 16),

        // Filter chips
        if (filters.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              return AdminFilterChip(
                label: filter.label,
                isSelected: selectedFilter == filter.value,
                onTap: () => onFilterChanged(filter.value),
                icon: filter.icon,
                selectedColor: filter.color,
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Filter option model
class FilterOption {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const FilterOption({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}

/// Empty state widget for filtered/searched lists
class AdminEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.gray400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: AppTheme.gray600),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

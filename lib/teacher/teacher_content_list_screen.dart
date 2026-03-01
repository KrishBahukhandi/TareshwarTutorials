import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../providers/content_providers.dart';
import 'widgets/teacher_layout.dart';

class TeacherContentListScreen extends ConsumerStatefulWidget {
  const TeacherContentListScreen({super.key});

  @override
  ConsumerState<TeacherContentListScreen> createState() => _TeacherContentListScreenState();
}

class _TeacherContentListScreenState extends ConsumerState<TeacherContentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    
    final videos = ref.watch(videoListProvider);
    final notes = ref.watch(notesListProvider);

    return TeacherLayout(
      currentRoute: '/teacher/content',
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Content',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your uploaded videos and notes',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search content...',
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
                      borderSide: BorderSide(color: AppTheme.success, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.gray200, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.success,
              unselectedLabelColor: AppTheme.gray600,
              indicatorColor: AppTheme.success,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_library, size: 18),
                      const SizedBox(width: 8),
                      const Text('Videos'),
                      videos.maybeWhen(
                        data: (items) => _buildCountBadge(items.length),
                        orElse: () => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.note, size: 18),
                      const SizedBox(width: 8),
                      const Text('Notes'),
                      notes.maybeWhen(
                        data: (items) => _buildCountBadge(items.length),
                        orElse: () => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder, size: 18),
                      SizedBox(width: 8),
                      Text('All'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosTab(videos, isMobile, padding),
                _buildNotesTab(notes, isMobile, padding),
                _buildAllContentTab(videos, notes, isMobile, padding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.gray700,
        ),
      ),
    );
  }

  Widget _buildVideosTab(AsyncValue videos, bool isMobile, double padding) {
    return videos.when(
      data: (items) {
        final videoList = items as List;
        final filtered = videoList.where((video) {
          if (_searchQuery.isEmpty) return true;
          return (video.title as String).toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.video_library_outlined,
            title: _searchQuery.isEmpty ? 'No videos yet' : 'No videos found',
            subtitle: _searchQuery.isEmpty
                ? 'Upload your first video lecture'
                : 'Try a different search term',
            actionLabel: _searchQuery.isEmpty ? 'Upload Video' : null,
            onAction: _searchQuery.isEmpty
                ? () => context.go('/teacher/videos/upload')
                : null,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(padding),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildVideoCard(filtered[index], isMobile);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Failed to load videos', style: TextStyle(color: AppTheme.gray700)),
            const SizedBox(height: 8),
            Text(error.toString(), style: TextStyle(color: AppTheme.gray500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab(AsyncValue notes, bool isMobile, double padding) {
    return notes.when(
      data: (items) {
        final notesList = items as List;
        final filtered = notesList.where((note) {
          if (_searchQuery.isEmpty) return true;
          return (note.title as String).toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.note_outlined,
            title: _searchQuery.isEmpty ? 'No notes yet' : 'No notes found',
            subtitle: _searchQuery.isEmpty
                ? 'Upload your first study material'
                : 'Try a different search term',
            actionLabel: _searchQuery.isEmpty ? 'Upload Notes' : null,
            onAction: _searchQuery.isEmpty
                ? () => context.go('/teacher/notes/upload')
                : null,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(padding),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildNoteCard(filtered[index], isMobile);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Failed to load notes', style: TextStyle(color: AppTheme.gray700)),
            const SizedBox(height: 8),
            Text(error.toString(), style: TextStyle(color: AppTheme.gray500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllContentTab(AsyncValue videos, AsyncValue notes, bool isMobile, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Videos Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Videos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          videos.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'No videos',
                  subtitle: null,
                  compact: true,
                );
              }
              final limited = items.take(3).toList();
              return Column(
                children: limited.map((video) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVideoCard(video, isMobile),
                )).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Notes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          notes.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.note_outlined,
                  title: 'No notes',
                  subtitle: null,
                  compact: true,
                );
              }
              final limited = items.take(3).toList();
              return Column(
                children: limited.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNoteCard(note, isMobile),
                )).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(dynamic video, bool isMobile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: isMobile ? 80 : 100,
              height: isMobile ? 60 : 75,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_filled,
                size: isMobile ? 32 : 40,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title?.toString() ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatContentSubtitle(video.courseName, video.batchName),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: AppTheme.gray600),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _confirmDelete(
                        context,
                        'video',
                        video.title?.toString() ?? 'this video',
                        () async {
                          await ref.read(videoServiceProvider).deleteVideo(
                            videoId: video.id as String,
                            storagePath: video.videoUrl as String,
                          );
                          ref.invalidate(videoListProvider);
                        },
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(dynamic note, bool isMobile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: isMobile ? 60 : 70,
              height: isMobile ? 60 : 70,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_rounded,
                size: isMobile ? 28 : 32,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title?.toString() ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatContentSubtitle(note.courseName, note.batchName),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: AppTheme.gray600),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _confirmDelete(
                        context,
                        'note',
                        note.title?.toString() ?? 'this note',
                        () async {
                          await ref.read(notesServiceProvider).deleteNote(
                            noteId: note.id as String,
                            storagePath: note.fileUrl as String,
                          );
                          ref.invalidate(notesListProvider);
                        },
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatContentSubtitle(dynamic courseName, dynamic batchName) {
    final course = courseName?.toString();
    final batch = batchName?.toString();
    if (course != null && batch != null) return '$course · $batch';
    if (course != null) return course;
    if (batch != null) return 'Batch: $batch';
    return 'No batch info';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 48 : 64,
              color: AppTheme.gray300,
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.gray600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String type, String title, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$type deleted successfully'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

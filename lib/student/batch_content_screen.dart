import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/notes_service.dart';
import '../services/storage_service.dart';
import '../services/student_service.dart';
import '../services/supabase_client.dart';
import 'widgets/student_layout.dart';

final batchNotesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, batchId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final notes = await StudentService().fetchStudentNotes(user.id);
  return notes.where((n) => n['batch_id'] == batchId).toList();
});

final batchVideosProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, batchId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final videos = await StudentService().fetchStudentVideos(user.id);
  return videos.where((v) => v['batch_id'] == batchId).toList();
});

class BatchContentScreen extends ConsumerStatefulWidget {
  const BatchContentScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<BatchContentScreen> createState() => _BatchContentScreenState();
}

class _BatchContentScreenState extends ConsumerState<BatchContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    final notes = ref.watch(batchNotesProvider(widget.batchId));
    final videos = ref.watch(batchVideosProvider(widget.batchId));

    return StudentLayout(
      currentRoute: '/student/batch/${widget.batchId}',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/student/my-courses'),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Course Content',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Videos and notes for this batch',
              style: TextStyle(color: AppTheme.gray600),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.gray200)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.gray600,
                indicatorColor: AppTheme.primaryBlue,
                tabs: const [
                  Tab(text: 'Videos'),
                  Tab(text: 'Notes'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _VideosTab(batchId: widget.batchId, videos: videos),
                  _NotesTab(batchId: widget.batchId, notes: notes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.batchId, required this.videos});

  final String batchId;
  final AsyncValue<List<Map<String, dynamic>>> videos;

  @override
  Widget build(BuildContext context) {
    return videos.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.video_library_outlined,
            title: 'No videos yet',
            subtitle: 'Your teacher hasn\'t uploaded videos for this batch.',
          );
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final v = items[i];
            final title = v['title']?.toString() ?? 'Untitled';
            final videoId = v['id'] as String;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_arrow, color: AppTheme.success),
                ),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: const Text('Tap to watch'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/student/videos/$videoId'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load videos: $e', style: TextStyle(color: AppTheme.error)),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.batchId, required this.notes});

  final String batchId;
  final AsyncValue<List<Map<String, dynamic>>> notes;

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final notesService = NotesService(storage);

    return notes.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.note_outlined,
            title: 'No notes yet',
            subtitle: 'Your teacher hasn\'t uploaded notes for this batch.',
          );
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final n = items[i];
            final title = n['title']?.toString() ?? 'Untitled';
            final storagePath = n['file_url'] as String?;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description, color: AppTheme.warning),
                ),
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: const Text('Tap to open'),
                trailing: const Icon(Icons.open_in_new),
                onTap: storagePath == null
                    ? null
                    : () async {
                        try {
                          final signedUrl = await notesService.createSignedUrl(storagePath);
                          if (context.mounted) {
                            // Open in browser tab
                            // ignore: use_build_context_synchronously
                            context.go(signedUrl);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to open note: $e'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load notes: $e', style: TextStyle(color: AppTheme.error)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppTheme.gray400),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.gray600)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/supabase_client.dart';
import '../services/teacher_service.dart';
import 'widgets/teacher_layout.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final batchDetailInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, batchId) async {
  final data = await supabase
      .from('batches')
      .select('*, courses(*)')
      .eq('id', batchId)
      .maybeSingle();
  return data;
});

final batchDetailStudentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, batchId) async {
  return TeacherService().fetchBatchStudents(batchId);
});

final batchDetailVideosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, batchId) async {
  final rows = await supabase
      .from('recorded_videos')
      .select()
      .eq('batch_id', batchId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(rows as List);
});

final batchDetailNotesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, batchId) async {
  final rows = await supabase
      .from('notes')
      .select()
      .eq('batch_id', batchId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(rows as List);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class BatchDetailScreen extends ConsumerStatefulWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends ConsumerState<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  void _refresh() {
    ref.invalidate(batchDetailStudentsProvider(widget.batchId));
    ref.invalidate(batchDetailVideosProvider(widget.batchId));
    ref.invalidate(batchDetailNotesProvider(widget.batchId));
    ref.invalidate(batchDetailInfoProvider(widget.batchId));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;

    final batchInfo = ref.watch(batchDetailInfoProvider(widget.batchId));
    final students = ref.watch(batchDetailStudentsProvider(widget.batchId));
    final videos = ref.watch(batchDetailVideosProvider(widget.batchId));
    final notes = ref.watch(batchDetailNotesProvider(widget.batchId));

    final courseName =
        batchInfo.valueOrNull?['courses']?['title']?.toString() ?? 'Batch';
    final startDate = batchInfo.valueOrNull?['start_date'] as String?;
    final endDate = batchInfo.valueOrNull?['end_date'] as String?;
    final seatLimit = batchInfo.valueOrNull?['seat_limit'] as int?;

    String? dateRange;
    if (startDate != null && endDate != null) {
      final s = DateTime.tryParse(startDate);
      final e = DateTime.tryParse(endDate);
      if (s != null && e != null) {
        dateRange =
            '${s.day}/${s.month}/${s.year} → ${e.day}/${e.month}/${e.year}';
      }
    }

    final studentCount = students.valueOrNull?.length ?? 0;
    final videoCount = videos.valueOrNull?.length ?? 0;
    final notesCount = notes.valueOrNull?.length ?? 0;

    return TeacherLayout(
      currentRoute: '/teacher/batches/${widget.batchId}/detail',
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Refresh
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/teacher/courses'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('All Batches'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.gray700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _refresh,
                      icon: Icon(Icons.refresh, color: AppTheme.gray600),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseName,
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gray900,
                            ),
                          ),
                          if (dateRange != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 13, color: AppTheme.gray500),
                                const SizedBox(width: 5),
                                Text(dateRange,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.gray600)),
                                if (seatLimit != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.people_outline,
                                      size: 13, color: AppTheme.gray500),
                                  const SizedBox(width: 5),
                                  Text('$seatLimit seats',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.gray600)),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Upload buttons
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.go(
                            '/teacher/batches/${widget.batchId}/upload-video'),
                        icon: const Icon(Icons.video_call, size: 18),
                        label: const Text('Upload Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => context.go(
                            '/teacher/batches/${widget.batchId}/upload-notes'),
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Upload Notes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),

                // Mobile upload buttons
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(
                              '/teacher/batches/${widget.batchId}/upload-video'),
                          icon: const Icon(Icons.video_call, size: 16),
                          label: const Text('Upload Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(
                              '/teacher/batches/${widget.batchId}/upload-notes'),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.gray600,
                  indicatorColor: AppTheme.primaryBlue,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 6),
                          Text('Students ($studentCount)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle, size: 16),
                          const SizedBox(width: 6),
                          Text('Videos ($videoCount)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description, size: 16),
                          const SizedBox(width: 6),
                          Text('Notes ($notesCount)'),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: AppTheme.gray200),
              ],
            ),
          ),

          // ── Tab views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Students tab
                _StudentsTab(
                  students: students,
                  padding: padding,
                ),
                // Videos tab
                _VideosTab(
                  videos: videos,
                  batchId: widget.batchId,
                  padding: padding,
                ),
                // Notes tab
                _NotesTab(
                  notes: notes,
                  batchId: widget.batchId,
                  padding: padding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Students Tab ─────────────────────────────────────────────────────────────

class _StudentsTab extends StatefulWidget {
  const _StudentsTab({required this.students, required this.padding});

  final AsyncValue<List<Map<String, dynamic>>> students;
  final double padding;

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return widget.students.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (list) {
        final filtered = list.where((s) {
          final q = _search.toLowerCase();
          if (q.isEmpty) return true;
          return (s['name'] as String? ?? '').toLowerCase().contains(q) ||
              (s['email'] as String? ?? '').toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  widget.padding, 16, widget.padding, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search students…',
                  prefixIcon:
                      Icon(Icons.search, color: AppTheme.gray400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.gray300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      icon: Icons.people_outline,
                      title: list.isEmpty
                          ? 'No students enrolled yet'
                          : 'No students match your search',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: widget.padding, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _StudentCard(student: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unknown';
    final email = student['email'] as String? ?? '';
    final enrolledAt = student['enrolled_at'] as String?;
    final isActive = student['is_active'] as bool? ?? true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.success.withValues(alpha: 0.12),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                    color: AppTheme.success, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900)),
                  const SizedBox(height: 2),
                  Text(email,
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.gray600)),
                  if (enrolledAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Enrolled: ${_fmt(enrolledAt)}',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isActive ? AppTheme.success : AppTheme.gray600,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String s) {
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Videos Tab ───────────────────────────────────────────────────────────────

class _VideosTab extends StatelessWidget {
  const _VideosTab(
      {required this.videos,
      required this.batchId,
      required this.padding});

  final AsyncValue<List<Map<String, dynamic>>> videos;
  final String batchId;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return videos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.video_library_outlined,
            title: 'No videos uploaded yet',
            subtitle: 'Tap "Upload Video" above to add the first lecture.',
            action: ElevatedButton.icon(
              onPressed: () =>
                  context.go('/teacher/batches/$batchId/upload-video'),
              icon: const Icon(Icons.video_call),
              label: const Text('Upload Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(padding),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final v = items[i];
            final title = v['title']?.toString() ?? 'Untitled';
            final seconds = (v['duration_seconds'] as num?)?.toInt() ?? 0;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_circle_filled,
                      color: AppTheme.success, size: 28),
                ),
                title: Text(title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: seconds > 0
                    ? Text(_fmtDuration(seconds),
                        style: TextStyle(
                            color: AppTheme.gray500, fontSize: 12))
                    : null,
                trailing: Icon(Icons.chevron_right,
                    color: AppTheme.gray400),
              ),
            );
          },
        );
      },
    );
  }

  String _fmtDuration(int s) {
    final m = s ~/ 60;
    final h = m ~/ 60;
    if (h > 0) return '${h}h ${m % 60}m';
    if (m > 0) return '${m}m ${(s % 60).toString().padLeft(2, '0')}s';
    return '${s}s';
  }
}

// ─── Notes Tab ────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab(
      {required this.notes,
      required this.batchId,
      required this.padding});

  final AsyncValue<List<Map<String, dynamic>>> notes;
  final String batchId;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return notes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.note_outlined,
            title: 'No notes uploaded yet',
            subtitle: 'Tap "Upload Notes" above to share study materials.',
            action: ElevatedButton.icon(
              onPressed: () =>
                  context.go('/teacher/batches/$batchId/upload-notes'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(padding),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final n = items[i];
            final title = n['title']?.toString() ?? 'Untitled';
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_rounded,
                      color: AppTheme.primaryBlue, size: 26),
                ),
                title: Text(title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Icon(Icons.chevron_right,
                    color: AppTheme.gray400),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppTheme.gray300),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray700)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.gray500)),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 12),
            Text('Failed to load data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gray600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

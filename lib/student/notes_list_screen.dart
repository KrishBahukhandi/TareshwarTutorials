import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../services/student_service.dart';
import '../services/supabase_client.dart';
import 'widgets/student_layout.dart';

// Provider for student notes
final studentNotesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  return await StudentService().fetchStudentNotes(user.id);
});

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final notes = ref.watch(studentNotesProvider);

    return StudentLayout(
      currentRoute: '/student/notes',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Study Materials',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Access and download notes from your enrolled courses',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.gray600,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Search Bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search notes...',
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
                  borderSide: BorderSide(color: AppTheme.warning, width: 2),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Notes List
            notes.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context, isMobile, isEmpty: true);
                }

                final filtered = _filterNotes(items);

                if (filtered.isEmpty) {
                  return _buildEmptyState(context, isMobile, isEmpty: false);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildNoteCard(context, filtered[index], isMobile);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load notes: $error',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterNotes(List<Map<String, dynamic>> items) {
    if (_searchQuery.isEmpty) return items;

    return items.where((note) {
      final title = note['title']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery);
    }).toList();
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note, bool isMobile) {
    final title = note['title']?.toString() ?? 'Untitled';
    final batch = note['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseName = course?['title']?.toString() ?? 'Unknown Course';
    final fileUrl = note['file_url'] as String?;

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
            // Document Icon
            Container(
              width: isMobile ? 50 : 60,
              height: isMobile ? 50 : 60,
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.description,
                color: AppTheme.warning,
                size: isMobile ? 24 : 28,
              ),
            ),
            const SizedBox(width: 16),

            // Note Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Download Button
            IconButton(
              onPressed: fileUrl != null
                  ? () async {
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Unable to open file'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              icon: Icon(
                Icons.download,
                color: fileUrl != null ? AppTheme.warning : AppTheme.gray400,
              ),
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isMobile, {required bool isEmpty}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.note_outlined : Icons.search_off,
              size: isMobile ? 64 : 80,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty ? 'No Notes Available' : 'No Notes Found',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? 'Enroll in a course to access study materials'
                  : 'Try adjusting your search',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

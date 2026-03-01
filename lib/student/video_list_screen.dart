import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/student_service.dart';
import '../services/supabase_client.dart';
import 'widgets/student_layout.dart';

// Provider for student videos
final studentVideosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  return await StudentService().fetchStudentVideos(user.id);
});

class VideoListScreen extends ConsumerStatefulWidget {
  const VideoListScreen({super.key});

  @override
  ConsumerState<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends ConsumerState<VideoListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isTablet = MediaQuery.of(context).size.width < 1200;
    final padding = isMobile ? 16.0 : 32.0;
    final videos = ref.watch(studentVideosProvider);

    return StudentLayout(
      currentRoute: '/student/videos',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Video Lectures',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Watch recorded lectures from your enrolled courses',
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
                hintText: 'Search videos...',
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
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Videos Grid
            videos.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context, isMobile, isEmpty: true);
                }

                final filtered = _filterVideos(items);

                if (filtered.isEmpty) {
                  return _buildEmptyState(context, isMobile, isEmpty: false);
                }

                final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isMobile ? 1.2 : 1.1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildVideoCard(context, filtered[index], isMobile);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load videos: $error',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterVideos(List<Map<String, dynamic>> items) {
    var filtered = items;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((video) {
        final title = video['title']?.toString().toLowerCase() ?? '';
        return title.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> video, bool isMobile) {
    final title = video['title']?.toString() ?? 'Untitled';
    final batch = video['batches'] as Map<String, dynamic>?;
    final course = batch?['courses'] as Map<String, dynamic>?;
    final courseName = course?['title']?.toString() ?? 'Unknown Course';
    final videoId = video['id'] as String;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: InkWell(
        onTap: () => context.go('/student/videos/$videoId'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: AppTheme.success,
                  ),
                ],
              ),
            ),

            // Video Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Course Name
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Play Button
                    Row(
                      children: [
                        Icon(Icons.play_arrow, size: 16, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          'Watch Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
              isEmpty ? Icons.video_library_outlined : Icons.search_off,
              size: isMobile ? 64 : 80,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty ? 'No Videos Available' : 'No Videos Found',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? 'Enroll in a course to access video lectures'
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

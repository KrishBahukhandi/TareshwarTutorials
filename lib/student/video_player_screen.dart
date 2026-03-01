import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../auth/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/recorded_video.dart';
import '../providers/content_providers.dart';
import 'widgets/student_layout.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Timer? _positionTimer;
  String? _signedUrl;
  bool _loadingUrl = true;
  String? _urlError;

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadSignedUrl(RecordedVideo video) async {
    if (_signedUrl != null) return;
    try {
      final url = await ref.read(videoServiceProvider).createSignedUrl(video.videoUrl);
      if (!mounted) return;
      setState(() {
        _signedUrl = url;
        _loadingUrl = false;
      });
      if (!kIsWeb) {
        await _initPlayer(video, url);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _urlError = e.toString();
        _loadingUrl = false;
      });
    }
  }

  Future<void> _initPlayer(RecordedVideo video, String signedUrl) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(signedUrl));
    await _controller!.initialize();

    final savedPosition = ref.read(playbackProvider.notifier).getPosition(video.id);
    if (savedPosition != null) {
      await _controller!.seekTo(savedPosition);
    }

    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_controller == null || !_controller!.value.isInitialized) return;
      ref.read(playbackProvider.notifier).savePosition(video.id, _controller!.value.position);
    });

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final videos = ref.watch(videoListProvider);
    final profile = ref.watch(profileProvider);

    return StudentLayout(
      currentRoute: '/student/videos',
      child: videos.when(
        data: (items) {
          final matching = items.where((item) => item.id == widget.videoId).toList();
          if (matching.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 72, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text('Video not found.', style: TextStyle(color: AppTheme.gray700, fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/student/videos'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Videos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final video = matching.first;

          // Trigger URL load once
          if (_signedUrl == null && _urlError == null && _loadingUrl) {
            Future.microtask(() => _loadSignedUrl(video));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/student/videos'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gray900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (video.courseName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              video.courseName!,
                              style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 28),

                // Video Player Area
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildVideoBody(video, profile, isMobile),
                  ),
                ),

                const SizedBox(height: 20),

                // Video Info
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow(Icons.title, 'Title', video.title),
                        if (video.courseName != null)
                          _infoRow(Icons.school, 'Course', video.courseName!),
                        if (video.batchName != null)
                          _infoRow(Icons.calendar_today, 'Batch Start', video.batchName!),
                        _infoRow(
                          Icons.timer,
                          'Duration',
                          _formatDuration(video.durationSeconds),
                        ),
                        _infoRow(
                          Icons.calendar_month,
                          'Uploaded',
                          '${video.createdAt.day}/${video.createdAt.month}/${video.createdAt.year}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildVideoBody(RecordedVideo video, dynamic profile, bool isMobile) {
    if (_loadingUrl) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.success),
              const SizedBox(height: 16),
              Text('Preparing video...', style: TextStyle(color: AppTheme.gray600)),
            ],
          ),
        ),
      );
    }

    if (_urlError != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text('Failed to load video', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_urlError!, style: TextStyle(color: AppTheme.gray600, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Web: show play button that opens in new tab
    if (kIsWeb) {
      return Column(
        children: [
          Container(
            height: isMobile ? 200 : 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled, size: 80, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(height: 16),
                Text(
                  video.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(video.durationSeconds),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(_signedUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  // Record view on play
                  if (profile != null) {
                    ref.read(analyticsServiceProvider).recordView(
                      studentId: profile.id,
                      contentType: 'video',
                      contentId: video.id,
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Watch Video (opens in browser)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The video will open in a new browser tab for the best viewing experience.',
            style: TextStyle(fontSize: 12, color: AppTheme.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Native: use VideoPlayer widget
    if (_controller == null || !_controller!.value.isInitialized) {
      return SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppTheme.success)),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        VideoProgressIndicator(
          _controller!,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          colors: VideoProgressColors(
            playedColor: AppTheme.success,
            bufferedColor: AppTheme.gray300,
            backgroundColor: AppTheme.gray200,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 48,
                color: AppTheme.success,
              ),
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                    if (profile != null) {
                      ref.read(analyticsServiceProvider).recordView(
                        studentId: profile.id,
                        contentType: 'video',
                        contentId: video.id,
                      );
                    }
                  }
                });
              },
            ),
            // Position indicator
            ValueListenableBuilder(
              valueListenable: _controller!,
              builder: (_, value, _) {
                final pos = value.position;
                final dur = value.duration;
                return Text(
                  '${_formatDuration(pos.inSeconds)} / ${_formatDuration(dur.inSeconds)}',
                  style: TextStyle(color: AppTheme.gray600, fontSize: 13),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gray500),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.gray700, fontSize: 14)),
          Expanded(child: Text(value, style: TextStyle(color: AppTheme.gray600, fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }
}

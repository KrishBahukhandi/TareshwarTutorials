import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../auth/auth_controller.dart';
import '../core/utils/recorded_video.dart';
import '../providers/content_providers.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Timer? _positionTimer;

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer(RecordedVideo video) async {
    final signedUrl = await ref.read(videoServiceProvider).createSignedUrl(
          video.videoUrl,
        );
    _controller = VideoPlayerController.networkUrl(Uri.parse(signedUrl));
    await _controller!.initialize();

    final savedPosition =
        ref.read(playbackProvider.notifier).getPosition(video.id);
    if (savedPosition != null) {
      await _controller!.seekTo(savedPosition);
    }

    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_controller == null) return;
      if (_controller!.value.isInitialized) {
        ref
            .read(playbackProvider.notifier)
            .savePosition(video.id, _controller!.value.position);
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(videoListProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: videos.when(
        data: (items) {
          final matching = items.where((item) => item.id == widget.videoId).toList();
          if (matching.isEmpty) {
            return const Center(child: Text('Video not found.'));
          }
          final selectedVideo = matching.first;

          return FutureBuilder(
            future:
                _controller == null ? _initPlayer(selectedVideo) : Future.value(),
            builder: (context, snapshot) {
              if (_controller == null || !_controller!.value.isInitialized) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.all(12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
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
                                      contentId: selectedVideo.id,
                                    );
                              }
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

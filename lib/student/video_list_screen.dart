import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/content_providers.dart';

class VideoListScreen extends ConsumerWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(videoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recorded Lectures')),
      body: videos.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No videos available yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final video = items[index];
              return Card(
                child: ListTile(
                  title: Text(video.title),
                  subtitle: Text('Duration: ${video.durationSeconds}s'),
                  trailing: const Icon(Icons.play_circle_outline),
                  onTap: () => context.go('/student/videos/${video.id}'),
                ),
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

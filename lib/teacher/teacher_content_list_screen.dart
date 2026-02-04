import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/content_providers.dart';

class TeacherContentListScreen extends ConsumerWidget {
  const TeacherContentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(videoListProvider);
    final notes = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Content')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Videos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          videos.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No videos uploaded yet.');
              }
              return Column(
                children: [
                  for (final video in items)
                    Card(
                      child: ListTile(
                        title: Text(video.title),
                        subtitle: Text('Batch: ${video.batchId}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(videoServiceProvider).deleteVideo(
                                  videoId: video.id,
                                  storagePath: video.videoUrl,
                                );
                            await ref.read(videoListProvider.notifier).refresh();
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          notes.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No notes uploaded yet.');
              }
              return Column(
                children: [
                  for (final note in items)
                    Card(
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Text('Batch: ${note.batchId}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(notesServiceProvider).deleteNote(
                                  noteId: note.id,
                                  storagePath: note.fileUrl,
                                );
                            await ref.read(notesListProvider.notifier).refresh();
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }
}

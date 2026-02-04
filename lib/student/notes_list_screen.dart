import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../providers/content_providers.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes & PDFs')),
      body: notes.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notes available yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = items[index];
              return Card(
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text('Batch: ${note.batchId}'),
                  trailing: const Icon(Icons.download_outlined),
                  onTap: () async {
                    try {
                      final file = await ref
                          .read(notesServiceProvider)
                          .downloadNote(storagePath: note.fileUrl);
                      if (profile != null) {
                        await ref.read(analyticsServiceProvider).recordView(
                              studentId: profile.id,
                              contentType: 'note',
                              contentId: note.id,
                            );
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloaded to ${file.path}')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  },
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

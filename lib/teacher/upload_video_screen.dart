import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/content_providers.dart';
import '../providers/data_providers.dart';

class UploadVideoScreen extends ConsumerStatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  ConsumerState<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends ConsumerState<UploadVideoScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  String? _filePath;
  String? _batchId;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(videoUploadProvider);
    final batches = ref.watch(teacherBatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Video title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (seconds)'),
              ),
              const SizedBox(height: 12),
              batches.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No batches assigned yet.');
                  }
                  return DropdownButtonFormField<String>(
                    value: _batchId,
                    items: items
                        .map((item) => DropdownMenuItem(
                              value: item.batch.id,
                              child: Text(item.course.title),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _batchId = value),
                    decoration: const InputDecoration(labelText: 'Batch'),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.video,
                  );
                  if (result?.files.single.path != null) {
                    setState(() => _filePath = result!.files.single.path);
                  }
                },
                child: Text(_filePath == null ? 'Pick video file' : 'Change file'),
              ),
              if (_filePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_filePath!, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 16),
              if (uploadState.status == UploadStatus.uploading)
                LinearProgressIndicator(value: uploadState.progress),
              if (uploadState.status == UploadStatus.failure)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    uploadState.error ?? 'Upload failed',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: uploadState.status == UploadStatus.uploading
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        final duration = int.tryParse(_durationController.text.trim());
                        if (title.isEmpty || duration == null || _filePath == null || _batchId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fill all fields.')),
                          );
                          return;
                        }
                        await ref.read(videoUploadProvider.notifier).uploadVideo(
                              batchId: _batchId!,
                              title: title,
                              filePath: _filePath!,
                              durationSeconds: duration,
                            );
                      },
                child: const Text('Upload Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

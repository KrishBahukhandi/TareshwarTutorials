import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../providers/content_providers.dart';
import '../services/teacher_service.dart';
import '../services/supabase_client.dart';
import 'widgets/teacher_layout.dart';

// Provider for teacher batches (notes upload)
final teacherBatchesSimpleProviderNotes = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final teacherId = supabase.auth.currentUser?.id;
  if (teacherId == null) return [];
  return await TeacherService().fetchTeacherBatches(teacherId);
});

class UploadNotesScreen extends ConsumerStatefulWidget {
  const UploadNotesScreen({super.key, this.preselectedBatchId});

  /// When navigated from a batch detail, this batch is pre-selected.
  final String? preselectedBatchId;

  @override
  ConsumerState<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends ConsumerState<UploadNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  Uint8List? _fileBytes;
  String? _fileName;
  String? _batchId;

  @override
  void initState() {
    super.initState();
    _batchId = widget.preselectedBatchId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _backRoute => widget.preselectedBatchId != null
      ? '/teacher/batches/${widget.preselectedBatchId}/detail'
      : '/teacher/content';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final padding = isMobile ? 16.0 : 32.0;
    final uploadState = ref.watch(notesUploadProvider);
    final batches = ref.watch(teacherBatchesSimpleProviderNotes);

    return TeacherLayout(
      currentRoute: '/teacher/notes/upload',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go(_backRoute),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Notes',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload study materials and resources for your students',
                          style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 32),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.gray200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Notes Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Notes Title *',
                          hintText: 'e.g., Chapter 5: Quadratic Equations',
                          prefixIcon: Icon(Icons.title, color: AppTheme.gray400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a notes title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Batch Selection
                      batches.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.warning),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: AppTheme.warning),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No batches assigned. Please contact admin.',
                                      style: TextStyle(color: AppTheme.warning),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _batchId,
                            decoration: InputDecoration(
                              labelText: 'Select Batch *',
                              prefixIcon: Icon(Icons.class_, color: AppTheme.gray400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                              ),
                            ),
                            items: items.map((item) {
                              final course = item['courses'] as Map<String, dynamic>?;
                              final courseTitle = course?['title'] ?? 'Unknown Course';
                              final startDate = DateTime.parse(item['start_date'] as String);
                              final formattedDate = '${startDate.day}/${startDate.month}/${startDate.year}';
                              return DropdownMenuItem(
                                value: item['id'] as String,
                                child: Text('$courseTitle ($formattedDate)', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _batchId = value),
                            validator: (value) {
                              if (value == null) return 'Please select a batch';
                              return null;
                            },
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(width: 12),
                              Text('Loading batches…', style: TextStyle(color: AppTheme.gray600)),
                            ],
                          ),
                        ),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Failed to load batches: $error',
                                  style: TextStyle(color: AppTheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // File Picker
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _fileBytes == null ? AppTheme.gray300 : AppTheme.primaryBlue,
                            width: _fileBytes == null ? 1 : 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              setState(() {
                                _fileBytes = result.files.single.bytes;
                                _fileName = result.files.single.name;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  _fileBytes == null ? Icons.upload_file_outlined : Icons.check_circle,
                                  size: 48,
                                  color: _fileBytes == null ? AppTheme.gray400 : AppTheme.primaryBlue,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _fileBytes == null ? 'Click to select document' : 'Document selected ✓',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _fileBytes == null ? AppTheme.gray700 : AppTheme.primaryBlue,
                                  ),
                                ),
                                if (_fileName != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _fileName!,
                                    style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (_fileBytes == null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supported: PDF, DOC, DOCX, PPT, PPTX, TXT',
                                    style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Upload Progress
                      if (uploadState.status == UploadStatus.uploading) ...[
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: uploadState.progress,
                          backgroundColor: AppTheme.gray200,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading… ${(uploadState.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // Error Message
                      if (uploadState.status == UploadStatus.failure) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  uploadState.error ?? 'Upload failed',
                                  style: TextStyle(color: AppTheme.error, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Upload Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: uploadState.status == UploadStatus.uploading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  if (_fileBytes == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Please select a document file'),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                    return;
                                  }

                                  final title = _titleController.text.trim();
                                  final messenger = ScaffoldMessenger.of(context);
                                  final router = GoRouter.of(context);

                                  await ref.read(notesUploadProvider.notifier).uploadNote(
                                        batchId: _batchId!,
                                        title: title,
                                        fileBytes: _fileBytes!,
                                        fileName: _fileName!,
                                      );

                                  final result = ref.read(notesUploadProvider);
                                  if (!mounted) return;

                                  if (result.status == UploadStatus.success) {
                                    _formKey.currentState!.reset();
                                    _titleController.clear();
                                    setState(() {
                                      _fileBytes = null;
                                      _fileName = null;
                                      if (widget.preselectedBatchId == null) _batchId = null;
                                    });
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Notes uploaded successfully!'),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.primaryBlue,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                    router.go(_backRoute);
                                  }
                                },
                          icon: Icon(
                            uploadState.status == UploadStatus.uploading
                                ? Icons.hourglass_empty
                                : Icons.upload_file,
                          ),
                          label: Text(
                            uploadState.status == UploadStatus.uploading
                                ? 'Uploading…'
                                : 'Upload Notes',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.gray300,
                            disabledForegroundColor: AppTheme.gray600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

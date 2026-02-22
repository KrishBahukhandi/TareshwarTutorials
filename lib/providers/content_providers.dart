import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../core/utils/note_item.dart';
import '../core/utils/recorded_video.dart';
import '../services/analytics_service.dart';
import '../services/notes_service.dart';
import '../services/storage_service.dart';
import '../services/video_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final videoServiceProvider = Provider<VideoService>(
  (ref) => VideoService(ref.read(storageServiceProvider)),
);
final notesServiceProvider = Provider<NotesService>(
  (ref) => NotesService(ref.read(storageServiceProvider)),
);
final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());

class VideoListController extends AsyncNotifier<List<RecordedVideo>> {
  @override
  Future<List<RecordedVideo>> build() async {
    final profile = ref.watch(profileProvider);
    if (profile == null) return [];
    if (profile.role == 'teacher') {
      return ref.read(videoServiceProvider).fetchForTeacher(profile.id);
    }
    return ref.read(videoServiceProvider).fetchForStudent();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final videoListProvider =
    AsyncNotifierProvider<VideoListController, List<RecordedVideo>>(
  VideoListController.new,
);

class NotesListController extends AsyncNotifier<List<NoteItem>> {
  @override
  Future<List<NoteItem>> build() async {
    final profile = ref.watch(profileProvider);
    if (profile == null) return [];
    if (profile.role == 'teacher') {
      return ref.read(notesServiceProvider).fetchForTeacher(profile.id);
    }
    return ref.read(notesServiceProvider).fetchForStudent();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final notesListProvider =
    AsyncNotifierProvider<NotesListController, List<NoteItem>>(
  NotesListController.new,
);

enum UploadStatus { idle, uploading, success, failure }

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? error;

  const UploadState({
    required this.status,
    this.progress = 0,
    this.error,
  });

  factory UploadState.idle() => const UploadState(status: UploadStatus.idle);

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

class VideoUploadController extends StateNotifier<UploadState> {
  VideoUploadController(this.ref) : super(UploadState.idle());

  final Ref ref;

  Future<void> uploadVideo({
    required String batchId,
    required String title,
    required Uint8List fileBytes,
    required String fileName,
    required int durationSeconds,
  }) async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;

    state = state.copyWith(status: UploadStatus.uploading, progress: 0);
    try {
      final storage = ref.read(storageServiceProvider);
      final storagePath = storage.buildStoragePathFromName(
        folder: batchId,
        fileName: fileName,
      );

      final uploadedPath = await storage.uploadFileBytes(
        bucket: 'recorded-videos',
        storagePath: storagePath,
        bytes: fileBytes,
        contentType: 'video/mp4',
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      await ref.read(videoServiceProvider).createVideo(
            batchId: batchId,
            title: title,
            videoUrl: uploadedPath,
            durationSeconds: durationSeconds,
            uploadedBy: profile.id,
          );

      await ref.read(videoListProvider.notifier).refresh();
      state = state.copyWith(status: UploadStatus.success, progress: 1);
    } catch (e) {
      state = state.copyWith(status: UploadStatus.failure, error: e.toString());
    }
  }
}

final videoUploadProvider =
    StateNotifierProvider.autoDispose<VideoUploadController, UploadState>(
  (ref) => VideoUploadController(ref),
);

class NotesUploadController extends StateNotifier<UploadState> {
  NotesUploadController(this.ref) : super(UploadState.idle());

  final Ref ref;

  Future<void> uploadNote({
    required String batchId,
    required String title,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;

    state = state.copyWith(status: UploadStatus.uploading, progress: 0);
    try {
      final storage = ref.read(storageServiceProvider);
      final storagePath = storage.buildStoragePathFromName(
        folder: batchId,
        fileName: fileName,
      );

      final uploadedPath = await storage.uploadFileBytes(
        bucket: 'notes-pdfs',
        storagePath: storagePath,
        bytes: fileBytes,
        contentType: 'application/pdf',
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      await ref.read(notesServiceProvider).createNote(
            batchId: batchId,
            title: title,
            fileUrl: uploadedPath,
            uploadedBy: profile.id,
          );

      await ref.read(notesListProvider.notifier).refresh();
      state = state.copyWith(status: UploadStatus.success, progress: 1);
    } catch (e) {
      state = state.copyWith(status: UploadStatus.failure, error: e.toString());
    }
  }
}

final notesUploadProvider =
    StateNotifierProvider.autoDispose<NotesUploadController, UploadState>(
  (ref) => NotesUploadController(ref),
);

class PlaybackController extends StateNotifier<Map<String, Duration>> {
  PlaybackController() : super(const {});

  void savePosition(String videoId, Duration position) {
    state = {...state, videoId: position};
  }

  Duration? getPosition(String videoId) => state[videoId];
}

final playbackProvider =
    StateNotifierProvider<PlaybackController, Map<String, Duration>>(
  (ref) => PlaybackController(),
);

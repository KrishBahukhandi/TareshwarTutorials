import '../core/utils/recorded_video.dart';
import 'storage_service.dart';
import 'supabase_client.dart';

class VideoService {
  VideoService(this._storageService);

  final StorageService _storageService;

  Future<List<RecordedVideo>> fetchForTeacher(String teacherId) async {
    final data = await supabase
        .from('recorded_videos')
        .select()
        .eq('uploaded_by', teacherId)
        .order('created_at', ascending: false);
    return data.map<RecordedVideo>((row) => RecordedVideo.fromMap(row)).toList();
  }

  Future<List<RecordedVideo>> fetchForStudent() async {
    final data = await supabase
        .from('recorded_videos')
        .select()
        .order('created_at', ascending: false);
    return data.map<RecordedVideo>((row) => RecordedVideo.fromMap(row)).toList();
  }

  Future<void> createVideo({
    required String batchId,
    required String title,
    required String videoUrl,
    required int durationSeconds,
    required String uploadedBy,
  }) async {
    await supabase.from('recorded_videos').insert({
      'batch_id': batchId,
      'title': title,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      'uploaded_by': uploadedBy,
    });
  }

  Future<void> deleteVideo({
    required String videoId,
    required String storagePath,
  }) async {
    await supabase.from('recorded_videos').delete().eq('id', videoId);
    await _storageService.deleteFile(
      bucket: 'recorded-videos',
      storagePath: storagePath,
    );
  }

  Future<String> createSignedUrl(String storagePath) async {
    return _storageService.createSignedUrl(
      bucket: 'recorded-videos',
      storagePath: storagePath,
      expiresInSeconds: 3600,
    );
  }
}

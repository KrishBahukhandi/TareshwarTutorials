import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class StorageService {
  /// Upload file bytes directly (works on web and native).
  Future<String> uploadFileBytes({
    required String bucket,
    required String storagePath,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.1);

    await supabase.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    onProgress?.call(1.0);
    return storagePath;
  }

  Future<String> createSignedUrl({
    required String bucket,
    required String storagePath,
    required int expiresInSeconds,
  }) async {
    return supabase.storage.from(bucket).createSignedUrl(
          storagePath,
          expiresInSeconds,
        );
  }

  Future<void> deleteFile({
    required String bucket,
    required String storagePath,
  }) async {
    await supabase.storage.from(bucket).remove([storagePath]);
  }

  String buildStoragePathFromName({
    required String folder,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$folder/$timestamp-$fileName';
  }
}

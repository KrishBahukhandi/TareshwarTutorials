import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class StorageService {
  Future<String> uploadFile({
    required String bucket,
    required String filePath,
    required String storagePath,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    final totalBytes = await file.length();
    final bytes = <int>[];
    var loadedBytes = 0;

    // Read file in chunks to provide local progress while preparing upload.
    await for (final chunk in file.openRead()) {
      bytes.addAll(chunk);
      loadedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress?.call(loadedBytes / totalBytes);
      }
    }

    final data = Uint8List.fromList(bytes);

    await supabase.storage.from(bucket).uploadBinary(
          storagePath,
          data,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

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

  String buildStoragePath({
    required String folder,
    required String filePath,
  }) {
    final fileName = path.basename(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$folder/$timestamp-$fileName';
  }
}

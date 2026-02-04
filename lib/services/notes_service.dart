import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/utils/note_item.dart';
import 'storage_service.dart';
import 'supabase_client.dart';

class NotesService {
  NotesService(this._storageService);

  final StorageService _storageService;

  Future<List<NoteItem>> fetchForTeacher(String teacherId) async {
    final data = await supabase
        .from('notes')
        .select()
        .eq('uploaded_by', teacherId)
        .order('created_at', ascending: false);
    return data.map<NoteItem>((row) => NoteItem.fromMap(row)).toList();
  }

  Future<List<NoteItem>> fetchForStudent() async {
    final data =
        await supabase.from('notes').select().order('created_at', ascending: false);
    return data.map<NoteItem>((row) => NoteItem.fromMap(row)).toList();
  }

  Future<void> createNote({
    required String batchId,
    required String title,
    required String fileUrl,
    required String uploadedBy,
  }) async {
    await supabase.from('notes').insert({
      'batch_id': batchId,
      'title': title,
      'file_url': fileUrl,
      'uploaded_by': uploadedBy,
    });
  }

  Future<void> deleteNote({
    required String noteId,
    required String storagePath,
  }) async {
    await supabase.from('notes').delete().eq('id', noteId);
    await _storageService.deleteFile(
      bucket: 'notes-pdfs',
      storagePath: storagePath,
    );
  }

  Future<String> createSignedUrl(String storagePath) async {
    return _storageService.createSignedUrl(
      bucket: 'notes-pdfs',
      storagePath: storagePath,
      expiresInSeconds: 3600,
    );
  }

  Future<File> downloadNote({
    required String storagePath,
  }) async {
    final signedUrl = await createSignedUrl(storagePath);
    final response = await http.get(Uri.parse(signedUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download note.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(storagePath);
    final file = File(path.join(directory.path, fileName));
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }
}

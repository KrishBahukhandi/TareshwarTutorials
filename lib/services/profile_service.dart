import '../core/utils/app_user.dart';
import 'supabase_client.dart';

class ProfileService {
  Future<AppUser?> fetchProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<void> upsertProfile({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    await supabase.from('profiles').upsert({
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    });
  }

  Future<void> updateProfile({
    required String id,
    String? name,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;

    if (updates.isEmpty) return;

    await supabase.from('profiles').update(updates).eq('id', id);
  }

  Future<void> updateRole({
    required String id,
    required String role,
  }) async {
    await supabase.from('profiles').update({'role': role}).eq('id', id);
  }

  Stream<AppUser?> profileStream(String userId) {
    final stream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : AppUser.fromMap(rows.first));
    return stream;
  }
}

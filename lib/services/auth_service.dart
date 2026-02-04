import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class AuthService {
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Session? get currentSession => supabase.auth.currentSession;
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/utils/app_user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_client.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? profile;
  final String? error;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.profile,
    this.error,
    this.isLoading = false,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initializing);

  AuthState copyWith({
    AuthStatus? status,
    AppUser? profile,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    authService: AuthService(),
    profileService: ProfileService(),
  ),
);

final profileProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).profile;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthService authService,
    required ProfileService profileService,
  })  : _authService = authService,
        _profileService = profileService,
        super(AuthState.initial()) {
    _init();
  }

  final AuthService _authService;
  final ProfileService _profileService;
  StreamSubscription<sb.AuthState>? _authSub;

  Future<void> _init() async {
    final session = _authService.currentSession;
    if (session?.user != null) {
      await _loadProfile(session!.user.id);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          profile: null,
          error: null,
          isLoading: false,
        );
        return;
      }
      await _loadProfile(session!.user.id);
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Confirm your email to finish sign up.',
        );
        return;
      }

      await _profileService.upsertProfile(
        id: user.id,
        name: name,
        email: email,
        role: 'student',
      );

      await _loadProfile(user.id);
    } on sb.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Sign in timed out. Please check your connection.'),
      );

      final user = response.user;
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Login failed. Please try again.',
        );
        return;
      }

      await _loadProfile(user.id);
    }    on sb.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.message,
      );
    } on TimeoutException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.message ?? 'Request timed out. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false);
    } on sb.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        profile: null,
        isLoading: false,
      );
    } on sb.AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error. Please try again.',
      );
    }
  }

  Future<void> _loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _profileService.fetchProfile(userId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Profile load timed out. Please check your connection.'),
      );
      if (profile == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Profile not found. Please contact support.',
        );
        return;
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: profile,
        isLoading: false,
        error: null,
      );
    } on TimeoutException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.message ?? 'Request timed out. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: 'Failed to load profile.',
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

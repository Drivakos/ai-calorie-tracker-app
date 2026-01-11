import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current User
  User? get currentUser => _supabase.auth.currentUser;

  // Current Session
  Session? get currentSession => _supabase.auth.currentSession;

  // Sign in with Email & Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Register with Email & Password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  // Sign in with Magic Link (email)
  Future<void> signInWithMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.calorietracker://login-callback/',
      );
    } catch (e) {
      debugPrint('Error sending magic link: $e');
      rethrow;
    }
  }

  // Sign in with Google (OAuth)
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.calorietracker://login-callback/',
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Apple (OAuth)
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.calorietracker://login-callback/',
      );
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

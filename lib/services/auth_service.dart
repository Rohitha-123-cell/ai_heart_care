import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (_client.auth.currentUser == null) return;

    try {
      await _client.auth.signOut();
    } on AuthException {
      // If the session is already invalid, the app should still consider the user logged out.
    }
  }

  User? get currentUser => _client.auth.currentUser;
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _client = Supabase.instance.client;

  // 🔐 SIGN UP
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // 🔐 LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 🚪 LOGOUT
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // 👤 CURRENT USER
  User? get currentUser => _client.auth.currentUser;
}
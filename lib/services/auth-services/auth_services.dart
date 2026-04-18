import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServices {
  final _client = Supabase.instance.client;

  // Register
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      password: password,
      email: email.trim(),
      data: {
        'username': username.trim(),
      }
    );
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      password: password,
      email: email.trim()
    );
  }

  // Sign Out
  Future<void> signOut() async{
    await _client.auth.signOut();
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _client.auth.updateUser(UserAttributes(data: metadata));
  }

  // Check Session
  Session? get currentSession => _client.auth.currentSession;

  // Get User
  User? get currentUser => _client.auth.currentUser;
}
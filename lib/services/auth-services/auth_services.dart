import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/core/constants/dio_client.dart';

class AuthServices {
  final _client = Supabase.instance.client;
  static const _usersTable = 'users';

  // Register
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim();
    final normalizedFullName = fullName.trim();

    final response = await _client.auth.signUp(
      password: password,
      email: normalizedEmail,
      data: {'username': normalizedUsername, 'full_name': normalizedFullName},
    );

    final user = response.user;
    final session = response.session ?? _client.auth.currentSession;

    if (user != null && session != null) {
      await _upsertProfile(
        id: user.id,
        email: normalizedEmail,
        username: normalizedUsername,
        fullName: normalizedFullName,
      );
    }

    return response;
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      password: password,
      email: email.trim().toLowerCase(),
    );

    final user = response.user ?? _client.auth.currentUser;
    if (user != null) {
      await _ensureProfileExists(user);
    }

    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _client.auth.updateUser(UserAttributes(data: metadata));
  }

  // Get current user's profile from public.users.
  Future<UserModel?> getProfile({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;

    final profile = await _fetchProfile(user.id);
    if (profile != null) return profile;

    return _ensureProfileExists(user);
  }

  Future<UserModel?> updateDisplayName({
    required String username,
    required String fullName,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    final normalizedUsername = username.trim();
    final normalizedFullName = fullName.trim();

    await updateUserMetadata({
      'username': normalizedUsername,
      'full_name': normalizedFullName,
    });

    final data = await _upsertProfile(
      id: user.id,
      email: user.email ?? '',
      username: normalizedUsername,
      fullName: normalizedFullName,
    );

    return UserModel.fromJson(data);
  }

  Future<UserModel?> updateAvatarUrl(String? avatarUrl) async {
    final user = currentUser;
    if (user == null) return null;

    await updateUserMetadata({'avatar_url': avatarUrl});

    final existingProfile = await getProfile();
    final data = await _upsertProfile(
      id: user.id,
      email: user.email ?? existingProfile?.email ?? '',
      username: existingProfile?.username ?? _metadataValue(user, 'username'),
      fullName: existingProfile?.fullName ?? _metadataValue(user, 'full_name'),
      avatarUrl: avatarUrl,
    );

    return UserModel.fromJson(data);
  }

  Future<UserModel?> uploadAvatar(File imageFile) async {
    try {
      final dioClient = DioClient();
      String filename = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      final response = await dioClient.dio.post(
        '/users/me/avatar',
        data: formData,
      );

      final userModel = UserModel.fromJson(response.data);
      
      // Update local Supabase auth metadata to match backend
      if (userModel.avatarUrl != null) {
        await updateUserMetadata({'avatar_url': userModel.avatarUrl});
      }
      
      return userModel;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Failed to upload avatar to server");
    }
  }

  Future<UserModel?> _fetchProfile(String userId) async {
    final data = await _client
        .from(_usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<UserModel?> _ensureProfileExists(User user) async {
    final existingProfile = await _fetchProfile(user.id);
    if (existingProfile != null) return existingProfile;

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final username = _metadataValue(user, 'username').isNotEmpty
        ? _metadataValue(user, 'username')
        : user.email?.split('@').first ?? '';
    final fullName = _metadataValue(user, 'full_name').isNotEmpty
        ? _metadataValue(user, 'full_name')
        : username;

    final data = await _upsertProfile(
      id: user.id,
      email: user.email ?? '',
      username: username,
      fullName: fullName,
      avatarUrl: metadata['avatar_url']?.toString(),
    );

    return UserModel.fromJson(data);
  }

  Future<Map<String, dynamic>> _upsertProfile({
    required String id,
    required String email,
    required String username,
    required String fullName,
    String? avatarUrl,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'updated_at': now,
    };

    final data = await _client
        .from(_usersTable)
        .upsert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(data);
  }

  String _metadataValue(User user, String key) {
    return user.userMetadata?[key]?.toString().trim() ?? '';
  }

  // Check Session
  Session? get currentSession => _client.auth.currentSession;

  // Get User
  User? get currentUser => _client.auth.currentUser;
}

/// User model representing a user profile in the system
class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Safe date parsing with fallback to current time
    final createdAtString = json['created_at']?.toString();
    final updatedAtString = json['updated_at']?.toString();

    DateTime parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return DateTime.now();
      }

      final parsed = DateTime.tryParse(dateString);
      if (parsed != null) {
        return parsed;
      }
      return DateTime.now();
    }

    return UserModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: parseDateTime(createdAtString),
      updatedAt: parseDateTime(updatedAtString),
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of UserModel with optional field replacements
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, username: $username)';
}

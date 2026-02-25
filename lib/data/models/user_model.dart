import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.avatarId,
    super.isPremium,
    super.isAnonymous,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatarId: json['avatar_id'] as int?,
      isPremium: (json['roles'] as List<dynamic>?)?.contains('premium') ?? false,
      isAnonymous: json['anonymous_id'] != null,
    );
  }

  factory UserModel.fromSupabase(User user, Map<String, dynamic>? profile) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: profile?['username'] ?? '',
      avatarId: profile?['avatar_id'] as int?,
      isPremium:
          (profile?['roles'] as List<dynamic>?)?.contains('premium') ?? false,
      isAnonymous: profile?['anonymous_id'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_id': avatarId,
      // roles is managed server-side; isPremium is derived on read
    };
  }
}

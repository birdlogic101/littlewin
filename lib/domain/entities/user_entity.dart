import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String username;
  final int? avatarId;
  final bool isPremium;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.avatarId, // 1–10, matches avatar_id int in DB
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [id, email, username, avatarId, isPremium];
}

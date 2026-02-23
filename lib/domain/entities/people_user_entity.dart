import 'package:equatable/equatable.dart';

/// A user shown in the People tab (search results or suggested users).
class PeopleUserEntity extends Equatable {
  final String userId;
  final String username;

  /// Avatar ID (1–10) for preset avatar. Null means use placeholder icon.
  final int? avatarId;

  /// Whether the current user is following this person.
  final bool isFollowing;

  const PeopleUserEntity({
    required this.userId,
    required this.username,
    this.avatarId,
    required this.isFollowing,
  });

  PeopleUserEntity copyWith({
    String? userId,
    String? username,
    int? avatarId,
    bool? isFollowing,
  }) {
    return PeopleUserEntity(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  List<Object?> get props => [userId, username, avatarId, isFollowing];
}

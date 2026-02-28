import 'package:equatable/equatable.dart';

/// A user shown in the People tab (search results or suggested users).
class PeopleUserEntity extends Equatable {
  final String userId;
  final String username;

  /// Avatar ID (1–10) for preset avatar. Null means use placeholder icon.
  final int? avatarId;

  /// Whether the current user is following this person.
  final bool isFollowing;

  /// Number of currently ongoing runs this user has.
  final int ongoingRunCount;

  const PeopleUserEntity({
    required this.userId,
    required this.username,
    this.avatarId,
    required this.isFollowing,
    this.ongoingRunCount = 0,
  });

  PeopleUserEntity copyWith({
    String? userId,
    String? username,
    int? avatarId,
    bool? isFollowing,
    int? ongoingRunCount,
  }) {
    return PeopleUserEntity(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      isFollowing: isFollowing ?? this.isFollowing,
      ongoingRunCount: ongoingRunCount ?? this.ongoingRunCount,
    );
  }

  @override
  List<Object?> get props => [userId, username, avatarId, isFollowing, ongoingRunCount];
}

import 'package:equatable/equatable.dart';

/// A public run card shown in the Explore feed.
/// Contains just enough data to render the card — username, challenge
/// title, streak, and an optional background image URL.
class ExploreRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;

  /// URL-safe slug used to identify the challenge (e.g. "16-hour-fasting").
  /// Required so the bloc can build a correct [ActiveRunEntity] on join.
  final String challengeSlug;

  final String userId;
  final String username;
  final int? avatarId;

  /// Current streak count for this run.
  final int currentStreak;

  /// Optional background photo URL sourced from a remote CDN / Supabase storage.
  final String? imageUrl;

  /// Optional local asset path — e.g. `assets/pictures/challenge_16-hour-fasting.jpg`.
  /// Takes precedence over [imageUrl] when both are set.
  final String? imageAsset;

  /// How many bets are currently placed on this run.
  final int recentBetCount;

  const ExploreRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeSlug,
    required this.userId,
    required this.username,
    this.avatarId,
    required this.currentStreak,
    this.imageUrl,
    this.imageAsset,
    this.recentBetCount = 0,
  });

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeSlug,
        userId,
        username,
        avatarId,
        currentStreak,
        imageUrl,
        imageAsset,
        recentBetCount,
      ];
}

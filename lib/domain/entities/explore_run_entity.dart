import 'package:equatable/equatable.dart';

/// A public run card shown in the Explore feed.
/// Contains just enough data to render the card — username, challenge
/// title, streak, and an optional background image URL.
class ExploreRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;
  final String? challengeDescription;

  /// URL-safe slug used to identify the challenge (e.g. "16-hour-fasting").
  /// Required so the bloc can build a correct [ActiveRunEntity] on join.
  final String challengeSlug;

  final String userId;
  final String username;
  final int? avatarId;
  final bool isPremium;

  /// Current streak count for this run.
  final int currentStreak;

  /// Optional background photo URL sourced from a remote CDN / Supabase storage.
  final String? imageUrl;

  /// Optional local asset path — e.g. `assets/pictures/challenge_16-hour-fasting.jpg`.
  /// Takes precedence over [imageUrl] when both are set.
  final String? imageAsset;

  /// How many bets are currently placed on this run.
  final int recentBetCount;

  /// Whether the run is already completed (Priority 3/4).
  /// If true, the bet button should be disabled.
  final bool isCompleted;

  const ExploreRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    this.challengeDescription,
    required this.challengeSlug,
    required this.userId,
    required this.username,
    this.avatarId,
    this.isPremium = false,
    required this.currentStreak,
    this.imageUrl,
    this.imageAsset,
    this.recentBetCount = 0,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeDescription,
        challengeSlug,
        userId,
        username,
        avatarId,
        isPremium,
        currentStreak,
        imageUrl,
        imageAsset,
        recentBetCount,
        isCompleted,
      ];

  ExploreRunEntity copyWith({
    String? runId,
    String? challengeId,
    String? challengeTitle,
    String? challengeDescription,
    String? challengeSlug,
    String? userId,
    String? username,
    int? avatarId,
    bool? isPremium,
    int? currentStreak,
    String? imageUrl,
    String? imageAsset,
    int? recentBetCount,
    bool? isCompleted,
  }) {
    return ExploreRunEntity(
      runId: runId ?? this.runId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDescription: challengeDescription ?? this.challengeDescription,
      challengeSlug: challengeSlug ?? this.challengeSlug,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      isPremium: isPremium ?? this.isPremium,
      currentStreak: currentStreak ?? this.currentStreak,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAsset: imageAsset ?? this.imageAsset,
      recentBetCount: recentBetCount ?? this.recentBetCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

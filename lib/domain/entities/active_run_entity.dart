import 'package:equatable/equatable.dart';

/// Represents a user's currently ongoing run on the Check-in screen.
class ActiveRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;
  final String? challengeDescription;
  final String challengeSlug;

  /// How many consecutive days the user has checked in.
  final int currentStreak;

  /// UTC start date of the run (yyyy-MM-dd).
  final String startDate;

  /// Whether the user has already checked in for today's UTC day.
  final bool hasCheckedInToday;

  /// The UTC date (yyyy-MM-dd) of the most recent successful check-in.
  final String? lastCheckinDay;

  /// Optional local asset path for background image.
  final String? imageAsset;

  /// Optional remote URL for background image.
  final String? imageUrl;

  /// Number of bets currently placed on this run.
  final int betCount;

  /// Whether the challenge associated with this run is public or private.
  final bool isPublic;

  const ActiveRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    this.challengeDescription,
    required this.challengeSlug,
    required this.currentStreak,
    required this.startDate,
    required this.hasCheckedInToday,
    this.lastCheckinDay,
    this.imageAsset,
    this.imageUrl,
    this.betCount = 0,
    this.isPublic = true,
  });

  // Sentinel used by [copyWith] so callers can explicitly pass `null`
  // to clear optional fields (the default `??` pattern cannot do this).
  static const Object _unset = Object();

  ActiveRunEntity copyWith({
    String? runId,
    String? challengeId,
    String? challengeTitle,
    String? challengeDescription,
    String? challengeSlug,
    int? currentStreak,
    String? startDate,
    bool? hasCheckedInToday,
    Object? lastCheckinDay = _unset,
    String? imageAsset,
    String? imageUrl,
    int? betCount,
    bool? isPublic,
  }) {
    return ActiveRunEntity(
      runId: runId ?? this.runId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDescription: challengeDescription ?? this.challengeDescription,
      challengeSlug: challengeSlug ?? this.challengeSlug,
      currentStreak: currentStreak ?? this.currentStreak,
      startDate: startDate ?? this.startDate,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      lastCheckinDay: identical(lastCheckinDay, _unset)
          ? this.lastCheckinDay
          : lastCheckinDay as String?,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      betCount: betCount ?? this.betCount,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeDescription,
        challengeSlug,
        currentStreak,
        startDate,
        hasCheckedInToday,
        lastCheckinDay,
        imageAsset,
        imageUrl,
        betCount,
        isPublic,
      ];
}

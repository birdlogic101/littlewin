import 'package:equatable/equatable.dart';

/// Represents a user's currently ongoing run on the Check-in screen.
class ActiveRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;
  final String challengeSlug;

  /// How many consecutive days the user has checked in.
  final int currentStreak;

  /// UTC start date of the run (yyyy-MM-dd).
  final String startDate;

  /// Whether the user has already checked in for today's UTC day.
  final bool hasCheckedInToday;

  /// The UTC date (yyyy-MM-dd) of the most recent successful check-in.
  ///
  /// Used by [RunsRepository.processCompletions] to detect a missed day:
  /// if [lastCheckinDay] ≠ yesterday's UTC date when the app opens on a
  /// new day, the run is considered completed.
  ///
  /// - `null` ← never checked in yet (e.g., just joined today).
  final String? lastCheckinDay;

  /// Optional local asset path for background image.
  final String? imageAsset;

  /// Optional remote URL for background image.
  final String? imageUrl;

  const ActiveRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeSlug,
    required this.currentStreak,
    required this.startDate,
    required this.hasCheckedInToday,
    this.lastCheckinDay,
    this.imageAsset,
    this.imageUrl,
  });

  // Sentinel used by [copyWith] so callers can explicitly pass `null`
  // to clear optional fields (the default `??` pattern cannot do this).
  static const Object _unset = Object();

  ActiveRunEntity copyWith({
    String? runId,
    String? challengeId,
    String? challengeTitle,
    String? challengeSlug,
    int? currentStreak,
    String? startDate,
    bool? hasCheckedInToday,
    // Use [_unset] as default so we can distinguish "not provided" from null.
    Object? lastCheckinDay = _unset,
    String? imageAsset,
    String? imageUrl,
  }) {
    return ActiveRunEntity(
      runId: runId ?? this.runId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeSlug: challengeSlug ?? this.challengeSlug,
      currentStreak: currentStreak ?? this.currentStreak,
      startDate: startDate ?? this.startDate,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      lastCheckinDay: identical(lastCheckinDay, _unset)
          ? this.lastCheckinDay
          : lastCheckinDay as String?,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeSlug,
        currentStreak,
        startDate,
        hasCheckedInToday,
        lastCheckinDay,
        imageAsset,
        imageUrl,
      ];
}

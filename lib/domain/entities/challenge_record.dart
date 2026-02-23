import 'package:equatable/equatable.dart';
import '../../domain/entities/completed_run_entity.dart';

/// A group of [CompletedRunEntity] for the same challenge.
///
/// The Records screen shows one [ChallengeRecord] per challenge,
/// even when there is only a single completed run.
class ChallengeRecord extends Equatable {
  final String challengeId;
  final String challengeTitle;
  final String challengeSlug;
  final String? imageAsset;
  final String? imageUrl;

  /// All completed runs for this challenge, newest [endDate] first.
  final List<CompletedRunEntity> runs;

  const ChallengeRecord({
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeSlug,
    required this.runs,
    this.imageAsset,
    this.imageUrl,
  });

  /// The highest [finalScore] across all runs (shown in the score ring).
  int get bestScore =>
      runs.map((r) => r.finalScore).reduce((a, b) => a > b ? a : b);

  /// Total number of completed runs for this challenge.
  int get runCount => runs.length;

  /// Build a sorted list of [ChallengeRecord] from a flat list of completed runs.
  ///
  /// Groups by [challengeId], sorts each group newest-first by [endDate],
  /// then sorts groups by [bestScore] descending.
  static List<ChallengeRecord> fromRuns(List<CompletedRunEntity> runs) {
    final map = <String, List<CompletedRunEntity>>{};
    for (final r in runs) {
      map.putIfAbsent(r.challengeId, () => []).add(r);
    }

    final groups = map.entries.map((e) {
      final sorted = List<CompletedRunEntity>.from(e.value)
        ..sort((a, b) => b.endDate.compareTo(a.endDate));
      final first = sorted.first;
      return ChallengeRecord(
        challengeId: e.key,
        challengeTitle: first.challengeTitle,
        challengeSlug: first.challengeSlug,
        imageAsset: first.imageAsset,
        imageUrl: first.imageUrl,
        runs: sorted,
      );
    }).toList();

    groups.sort((a, b) => b.bestScore.compareTo(a.bestScore));
    return groups;
  }

  @override
  List<Object?> get props =>
      [challengeId, challengeTitle, challengeSlug, runs, imageAsset, imageUrl];
}

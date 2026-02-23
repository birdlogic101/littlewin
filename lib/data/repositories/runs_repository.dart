import 'dart:async';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import 'completed_runs_repository.dart';

/// Shared in-memory store for the current user's active runs.
///
/// Both [ExploreBloc] and [CheckinBloc] receive the same instance
/// (injected from AppShell) so that a "Join" action on Explore is
/// immediately visible on the Check-in screen without a round-trip.
///
/// Call [processCompletions] whenever a UTC day rollover is detected to
/// move missed runs into [CompletedRunsRepository].
///
/// Replace with Supabase-backed calls when the backend is wired.
class RunsRepository {
  RunsRepository({List<ActiveRunEntity>? initial})
      : _runs = List<ActiveRunEntity>.from(initial ?? _defaultRuns());

  final List<ActiveRunEntity> _runs;
  final _controller = StreamController<List<ActiveRunEntity>>.broadcast();

  /// Current snapshot of the user's active runs.
  List<ActiveRunEntity> get activeRuns => List.unmodifiable(_runs);

  /// Emits a new snapshot every time the list changes.
  Stream<List<ActiveRunEntity>> get stream => _controller.stream;

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Prepend [run] to the list (newest joined → top of Check-in).
  /// No-op if a run with the same [runId] already exists.
  void addRun(ActiveRunEntity run) {
    if (_runs.any((r) => r.runId == run.runId)) return;
    _runs.insert(0, run);
    _controller.add(List.unmodifiable(_runs));
  }

  /// Replace an existing run (e.g. after a check-in optimistic update).
  void updateRun(ActiveRunEntity updated) {
    final idx = _runs.indexWhere((r) => r.runId == updated.runId);
    if (idx == -1) return;
    _runs[idx] = updated;
    _controller.add(List.unmodifiable(_runs));
  }

  // ── Day rollover ───────────────────────────────────────────────────────────

  /// Called when the app detects a new UTC day (on resume / cold start).
  ///
  /// For each active run:
  /// - If [lastCheckinDay] == [yesterday]: the user checked in yesterday
  ///   → the run survives. Reset [hasCheckedInToday] to `false` for the
  ///   new day.
  /// - Otherwise: the user missed yesterday → the run is complete.
  ///   Create a [CompletedRunEntity] and move it to [completedRepo].
  ///
  /// Emits the updated active list and (via [completedRepo]) the completed list.
  void processCompletions(
    String todayUtc,
    CompletedRunsRepository completedRepo,
  ) {
    final yesterday = _dayBefore(todayUtc);
    final toRemove = <String>[];

    for (var i = 0; i < _runs.length; i++) {
      final run = _runs[i];

      if (run.lastCheckinDay == yesterday) {
        // Survived ─ reset daily flag for the new UTC day.
        _runs[i] = run.copyWith(hasCheckedInToday: false);
      } else {
        // Missed ─ complete the run.
        completedRepo.addRun(
          CompletedRunEntity(
            runId: 'completed-${run.runId}-$yesterday',
            challengeId: run.challengeId,
            challengeTitle: run.challengeTitle,
            challengeSlug: run.challengeSlug,
            finalScore: run.currentStreak,
            startDate: run.startDate,
            endDate: yesterday,
            imageAsset: run.imageAsset,
            imageUrl: run.imageUrl,
          ),
        );
        toRemove.add(run.runId);
      }
    }

    _runs.removeWhere((r) => toRemove.contains(r.runId));
    _controller.add(List.unmodifiable(_runs));
  }

  void dispose() => _controller.close();

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the UTC date string for the day before [dateUtc] (yyyy-MM-dd).
  static String _dayBefore(String dateUtc) {
    final d = DateTime.parse(dateUtc).toUtc();
    final prev = d.subtract(const Duration(days: 1));
    return '${prev.year}-'
        '${prev.month.toString().padLeft(2, '0')}-'
        '${prev.day.toString().padLeft(2, '0')}';
  }

  // ── Default seed data ──────────────────────────────────────────────────────

  /// Seeds three active runs with today's UTC date as [startDate] so they are
  /// always treated as fresh (no missed days until the next real day rollover).
  static List<ActiveRunEntity> _defaultRuns() {
    final now = DateTime.now().toUtc();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return [
      ActiveRunEntity(
        runId: 'run-my-1',
        challengeId: 'ch-02',
        challengeTitle: '16-Hour Fasting',
        challengeSlug: '16-hour-fasting',
        currentStreak: 14,
        startDate: today,
        hasCheckedInToday: false,
        lastCheckinDay: null,
        imageAsset: 'assets/pictures/challenge_16-hour-fasting.jpg',
      ),
      ActiveRunEntity(
        runId: 'run-my-2',
        challengeId: 'ch-11',
        challengeTitle: '10,000 Steps',
        challengeSlug: '10000-steps',
        currentStreak: 7,
        startDate: today,
        hasCheckedInToday: false,
        lastCheckinDay: null,
        imageAsset: 'assets/pictures/challenge_10000-steps.jpg',
      ),
      ActiveRunEntity(
        runId: 'run-my-3',
        challengeId: 'ch-05',
        challengeTitle: '16-Hour Offscreen',
        challengeSlug: '16-hour-offscreen',
        currentStreak: 3,
        startDate: today,
        hasCheckedInToday: false,
        lastCheckinDay: null,
        imageAsset: 'assets/pictures/challenge_16-hour-offscreen.jpg',
      ),
    ];
  }
}

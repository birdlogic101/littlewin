import 'dart:async';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import '../datasources/run_remote_datasource.dart';
import 'completed_runs_repository.dart';

/// Shared in-memory store for the current user's active runs.
///
/// Both [ExploreBloc] and [CheckinBloc] receive the same instance
/// (injected from AppShell) so that a "Join" action on Explore is
/// immediately visible on the Check-in screen without a round-trip.
///
/// On startup, call [initialize] to populate from Supabase. In development
/// or tests, pass `initial` runs to the constructor to skip the network call.
///
/// Call [processCompletions] whenever a UTC day rollover is detected to
/// move missed runs into [CompletedRunsRepository].
class RunsRepository {
  RunsRepository({
    List<ActiveRunEntity>? initial,
    RunRemoteDataSource? datasource,
  })  : _runs = List<ActiveRunEntity>.from(initial ?? _defaultRuns()),
        _datasource = datasource;

  final List<ActiveRunEntity> _runs;
  final RunRemoteDataSource? _datasource;
  final _controller = StreamController<List<ActiveRunEntity>>.broadcast();

  /// Current snapshot of the user's active runs.
  List<ActiveRunEntity> get activeRuns => List.unmodifiable(_runs);

  /// Emits a new snapshot every time the list changes.
  Stream<List<ActiveRunEntity>> get stream => _controller.stream;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads the current user's active runs from Supabase and replaces the
  /// in-memory list, then runs [processCompletions] to handle any runs
  /// missed while the app was closed.
  ///
  /// Safe to call multiple times (idempotent).
  /// If [_datasource] is null (tests / Supabase not configured), this is a no-op.
  Future<void> initialize(CompletedRunsRepository completedRepo) async {
    if (_datasource == null) return;
    try {
      final remoteRuns = await _datasource.fetchMyRuns();
      _runs
        ..clear()
        ..addAll(remoteRuns);
      _controller.add(List.unmodifiable(_runs));
      // Apply client-side completion pass for any remaining gaps
      processCompletions(_todayUtc(), completedRepo);
    } catch (e) {
      // Non-fatal: keep whatever runs are already in memory
      // ignore: avoid_print
      print('[RunsRepository] initialize error (non-fatal): $e');
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Prepend [run] to the list (newest joined → top of Check-in).
  /// No-op if a run with the same [runId] already exists.
  /// Also persists the new run to Supabase if a datasource is configured.
  Future<void> addRun(ActiveRunEntity run) async {
    if (_runs.any((r) => r.runId == run.runId)) return;

    // If we have a real datasource, persist to Supabase and get back the
    // server-generated UUID. Then update the local entity's runId.
    ActiveRunEntity toStore = run;
    if (_datasource != null) {
      try {
        final serverId = await _datasource.createRun(
          challengeId: run.challengeId,
        );
        toStore = run.copyWith(runId: serverId);
      } catch (e) {
        // ignore: avoid_print
        print('[RunsRepository] createRun error (non-fatal): $e');
        // Fall through — keep the optimistic local entity
      }
    }

    _runs.insert(0, toStore);
    _controller.add(List.unmodifiable(_runs));
  }

  /// Replace an existing run (e.g. after a check-in optimistic update).
  void updateRun(ActiveRunEntity updated) {
    final idx = _runs.indexWhere((r) => r.runId == updated.runId);
    if (idx == -1) return;
    _runs[idx] = updated;
    _controller.add(List.unmodifiable(_runs));
  }

  /// Records a check-in for [runId] on today's UTC day.
  ///
  /// Updates the in-memory entity immediately (optimistic), then persists
  /// to Supabase asynchronously. Idempotent — duplicate check-ins are ignored
  /// by the unique constraint on `checkins(run_id, check_in_day_utc)`.
  Future<void> checkin(String runId) async {
    final idx = _runs.indexWhere((r) => r.runId == runId);
    if (idx == -1) return;

    final today = _todayUtc();
    final run = _runs[idx];

    // Optimistic update
    final newStreak = run.currentStreak + 1;
    _runs[idx] = run.copyWith(
      currentStreak: newStreak,
      hasCheckedInToday: true,
      lastCheckinDay: today,
    );
    _controller.add(List.unmodifiable(_runs));

    // Persist to Supabase
    if (_datasource != null) {
      try {
        await _datasource.recordCheckin(runId: runId, newStreak: newStreak);
      } catch (e) {
        // ignore: avoid_print
        print('[RunsRepository] recordCheckin error (non-fatal): $e');
        // Keep the optimistic update; retry on next sync
      }
    }
  }

  // ── Day rollover ───────────────────────────────────────────────────────────

  /// Called whenever the app opens (cold start) or returns to foreground on a
  /// new UTC day.
  ///
  /// **Survival rule**: a run survives if the user checked in on `todayUtc - 1`
  /// (i.e. `lastCheckinDay == yesterday`). The run is reset so the new UTC day
  /// is available for check-in.
  ///
  /// **Day-1 rule**: if `run.startDate == todayUtc`, the run just started and
  /// the first eligible check-in day is *today* — it cannot yet be missed.
  /// The run survives unconditionally and `hasCheckedInToday` is cleared.
  ///
  /// **Missed run**: any other case (lastCheckinDay == null with startDate in
  /// the past, or lastCheckinDay older than yesterday) means at least one UTC
  /// day has been skipped → the run is completed with the current streak as the
  /// final score (which is 0 if the user never checked in at all).
  ///
  /// This method is **idempotent**: repeated calls produce the same result.
  void processCompletions(
    String todayUtc,
    CompletedRunsRepository completedRepo,
  ) {
    final yesterday = dayBefore(todayUtc);
    final toRemove = <String>[];

    for (var i = 0; i < _runs.length; i++) {
      final run = _runs[i];

      // ── Day-1 rule ─────────────────────────────────────────────────────────
      // The run started today: first eligible check-in is today, nothing missed.
      if (run.startDate == todayUtc) {
        _runs[i] = run.copyWith(hasCheckedInToday: false);
        continue;
      }

      // ── Survival rule ──────────────────────────────────────────────────────
      // User checked in yesterday → run is alive for today.
      if (run.lastCheckinDay == yesterday) {
        _runs[i] = run.copyWith(hasCheckedInToday: false);
        continue;
      }

      // ── Missed run ─────────────────────────────────────────────────────────
      // Covers:
      //   • lastCheckinDay == null AND startDate < todayUtc (never checked in)
      //   • lastCheckinDay is older than yesterday (multi-day gap / traveller)
      //
      // finalScore = currentStreak at the point of failure:
      //   • 0 if the user never checked in
      //   • last consecutive streak if they fell off later
      //
      // endDate = yesterday (the last day that *should* have had a check-in).
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

    _runs.removeWhere((r) => toRemove.contains(r.runId));
    if (toRemove.isNotEmpty) {
      _controller.add(List.unmodifiable(_runs));
    }
  }

  /// Resets [hasCheckedInToday] to `false` for any run whose [lastCheckinDay]
  /// is not [todayUtc].
  ///
  /// Called by [CheckinBloc] on fetch to guard against the case where the app
  /// was backgrounded across a UTC midnight without triggering a lifecycle
  /// resume event (e.g. process kill + OS restore).
  void clearStaleCheckinFlags(String todayUtc) {
    bool changed = false;
    for (var i = 0; i < _runs.length; i++) {
      final run = _runs[i];
      if (run.hasCheckedInToday && run.lastCheckinDay != todayUtc) {
        _runs[i] = run.copyWith(hasCheckedInToday: false);
        changed = true;
      }
    }
    if (changed) _controller.add(List.unmodifiable(_runs));
  }

  void dispose() => _controller.close();

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns the UTC date string for the day before [dateUtc] (yyyy-MM-dd).
  /// Public so unit tests and [CompletedRunsRepository] can use it.
  ///
  /// IMPORTANT: always parse with an explicit UTC suffix so the result is
  /// correct regardless of the host machine's local timezone.
  static String dayBefore(String dateUtc) {
    // Appending T00:00:00Z ensures DateTime.parse treats the input as UTC
    // midnight even on machines whose local timezone is ahead of UTC.
    final d = DateTime.parse('${dateUtc}T00:00:00Z');
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

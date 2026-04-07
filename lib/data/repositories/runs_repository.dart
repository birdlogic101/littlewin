import 'dart:async';
import '../../domain/entities/explore_run_entity.dart';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../datasources/run_remote_datasource.dart';
import 'completed_runs_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:injectable/injectable.dart';

/// Thrown by [RunsRepository.addRun] when the user already has an active run
/// for the same challenge slug.
class AlreadyParticipatingException implements Exception {
  final String challengeSlug;
  const AlreadyParticipatingException(this.challengeSlug);

  @override
  String toString() =>
      'AlreadyParticipatingException: already active on "$challengeSlug"';
}


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
@lazySingleton
class RunsRepository {
  /// Main constructor — used by the DI container (injectable).
  /// [datasource] enables real Supabase operations; omit for offline use.
  RunsRepository({
    RunRemoteDataSource? datasource,
  })  : _runs = <ActiveRunEntity>[],
        _datasource = datasource;

  /// Test / in-memory constructor. Seeds the repository with [initial] runs
  /// without requiring a remote datasource.
  RunsRepository.seeded(List<ActiveRunEntity> initial)
      : _runs = List.of(initial),
        _datasource = null;


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
      // ignore: avoid_print
      print('⚠️ [RunsRepository] initialize error (non-fatal): $e');
    }
  }

  /// Returns true if there is an ongoing run for this challenge slug.
  bool isChallengeActive(String slug) {
    return _runs.any((r) => r.challengeSlug == slug);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> addRun(ActiveRunEntity run) async {
    if (_runs.any((r) => r.runId == run.runId)) return;

    // Safety check: don't allow duplicate active runs for the same challenge
    if (isChallengeActive(run.challengeSlug)) {
      throw AlreadyParticipatingException(run.challengeSlug);
    }

    // If we have a real datasource, persist to Supabase and get back the
    // server-generated UUID. Then update the local entity's runId.
    ActiveRunEntity toStore = run;
    if (_datasource != null) {
      try {
        final serverId = await _datasource.createRun(
          challengeId: run.challengeId,
        );
        toStore = run.copyWith(runId: serverId);
      } on PostgrestException catch (e) {
        if (e.message.contains('ALREADY_JOINED')) {
          throw AlreadyParticipatingException(run.challengeSlug);
        }
        rethrow;
      }
    }

    _runs.insert(0, toStore);
    _controller.add(List.unmodifiable(_runs));
  }

  /// High-level method to join a challenge by ID.
  /// Handles temporary entity creation and RPC trigger.
  Future<void> joinChallenge(
    String challengeId, {
    String title = 'Joining...',
    String slug = '',
    String? imageAsset,
  }) async {
    final now = DateTime.now().toUtc();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final tempRun = ActiveRunEntity(
      runId: 'temp-$challengeId-${now.millisecondsSinceEpoch}',
      challengeId: challengeId,
      challengeTitle: title,
      challengeSlug: slug.isNotEmpty ? slug : 'joining-$challengeId',
      currentStreak: 0,
      startDate: today,
      hasCheckedInToday: false,
    );

    await addRun(tempRun);
  }

  /// Manually injects a run into the local list (e.g. after a challenge is 
  /// created on the server and returned with its run ID).
  void injectRun(ActiveRunEntity run) {
    if (_runs.any((r) => r.runId == run.runId)) return;
    _runs.insert(0, run);
    _controller.add(List.unmodifiable(_runs));
  }

  /// Fetches a batch of public runs for the Explore screen.
  Future<List<ExploreRunEntity>> fetchExploreFeed({
    int limit = 5,
    int offset = 0,
  }) async {
    if (_datasource == null) return [];
    return await _datasource.fetchExploreFeed(limit: limit, offset: offset);
  }

  /// Fetches ongoing runs for a specific user (other than the current user).
  Future<List<ActiveRunEntity>> fetchUserRuns(String userId) async {
    if (_datasource == null) return [];
    return await _datasource.fetchUserRuns(userId);
  }

  /// Fetches completed runs for a specific user.
  Future<List<CompletedRunEntity>> fetchUserCompletedRuns(String userId) async {
    if (_datasource == null) return [];
    return await _datasource.fetchUserCompletedRuns(userId);
  }

  /// Dismisses a run for the current user.
  Future<void> dismissRun(String runId) async {
    if (_datasource == null) return;
    await _datasource.dismissRun(runId);
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
  /// Updates the in-memory entity immediately (optimistic), then delegates
  /// to the server-side RPC which handles streak increment, bet settlement,
  /// and notification creation atomically.
  ///
  /// Returns a [BetResolutionEntity] if the new streak triggered won bets,
  /// otherwise returns `null`.
  Future<BetResolutionEntity?> checkin(String runId) async {
    final idx = _runs.indexWhere((r) => r.runId == runId);
    if (idx == -1) return null;

    final run = _runs[idx];

    // Defense-in-depth: never double-check-in. The BLoC guards this too, but
    // the repository must be the authoritative gate since it owns the state.
    if (run.hasCheckedInToday) {
      // ignore: avoid_print
      print('[RunsRepository] checkin ignored: $runId already checked in today.');
      return null;
    }

    final today = _todayUtc();
    final yesterday = dayBefore(today);

    // Guard: if the user missed the window, they can't check in anymore.
    // The run should have been processCompletions-ed, but if the UI is stale,
    // we catch it here.
    //
    // A run is expired only if it has a prior check-in AND that check-in is
    // older than yesterday (meaning at least one full UTC day was skipped).
    // A null lastCheckinDay means "never checked in yet" which is always valid
    // — it covers both Day-1 runs AND runs started earlier that were never
    // touched (the latter will have been cleared by processCompletions already,
    // so we should rarely reach this branch with a stale null, but we must not
    // reject it).
    final hasExpiredStreak = run.lastCheckinDay != null &&
        run.lastCheckinDay != today &&
        run.lastCheckinDay != yesterday;
    if (hasExpiredStreak) {
      // ignore: avoid_print
      print('[RunsRepository] checkin refused: run $runId has expired (lastCheckinDay=${run.lastCheckinDay}).');
      return null;
    }

    // Optimistic update
    final originalRun = run;
    final newStreak = run.currentStreak + 1;
    _runs[idx] = run.copyWith(
      currentStreak: newStreak,
      hasCheckedInToday: true,
      lastCheckinDay: today,
    );
    _controller.add(List.unmodifiable(_runs));

    // Persist to Supabase via RPC
    if (_datasource != null) {
      try {
        final resolution = await _datasource.recordCheckin(
          runId: runId,
          challengeTitle: run.challengeTitle,
          todayUtc: today,
        );
        
        // Success: the server might have changed the streak (redundant checkin return)
        // or resolved bets. If we get a resolution, it means the server 
        // authoritative state is now in our hands.
        if (resolution != null) {
          final updatedRun = _runs[idx].copyWith(
            currentStreak: resolution.newStreak,
            hasCheckedInToday: true,
            lastCheckinDay: today,
          );
          _runs[idx] = updatedRun;
          _controller.add(List.unmodifiable(_runs));
        }
        
        return resolution;
      } catch (e) {
        // ignore: avoid_print
        print('❌ [RunsRepository] recordCheckin failed for $runId: $e');
        
        // REVERT: Replace with original state on failure so the UI pops back
        final currentIdx = _runs.indexWhere((r) => r.runId == runId);
        if (currentIdx != -1) {
          _runs[currentIdx] = originalRun;
          _controller.add(List.unmodifiable(_runs));
        }
        rethrow;
      }
    }
    return null;
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
        continue;
      }

      // ── Survival rule ──────────────────────────────────────────────────────
      // User checked in yesterday → run is alive for today.
      if (run.lastCheckinDay == yesterday) {
        _runs[i] = run.copyWith(hasCheckedInToday: false);
        continue;
      }

      // If already checked in today (e.g. just performed check-in and re-synced),
      // the run is definitely alive and should NOT be processed as missed.
      if (run.lastCheckinDay == todayUtc) {
        continue;
      }

      // ── Missed run ─────────────────────────────────────────────────────────
      // Covers:
      //   • lastCheckinDay == null AND startDate < todayUtc (never checked in)
      //   • lastCheckinDay is older than yesterday (multi-day gap)
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

}

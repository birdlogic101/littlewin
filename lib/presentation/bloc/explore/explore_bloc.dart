import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'explore_event.dart';
import 'explore_state.dart';
import '../../../domain/entities/explore_run_entity.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../data/repositories/runs_repository.dart';

/// The challenger0 system user UUID used to identify Community Challenges.
const _challenger0Id = '00000000-0000-0000-0000-000000000000';

@injectable 
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final RunsRepository _runsRepository;

  /// Tracks the current cycle number for generating unique synthetic IDs.
  int _cycleCounter = 0;

  ExploreBloc({required RunsRepository runsRepository})
      : _runsRepository = runsRepository,
        super(const ExploreState.initial()) {
    on<ExploreFetchRequested>(_onFetch);
    on<ExploreLoadMoreRequested>(_onLoadMore);
    on<ExploreRunDismissed>(_onDismiss);
    on<ExploreRunJoined>(_onJoin);
    on<ExploreClearJoinError>(_onClearJoinError);
    on<ExploreRunBetPlaced>(_onRunBetPlaced);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    ExploreFetchRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreState.loading());
    try {
      // Fetch a large initial batch — server returns P1-P4 in priority order.
      final allRuns = await _runsRepository.fetchExploreFeed(
        limit: 100,
        offset: 0,
      );

      // Split: challenger0 runs go into the Community Challenges (fallback) pool, everything else is ongoing/followed content.
      final ongoingRuns = <ExploreRunEntity>[];
      final communityChallenges = <ExploreRunEntity>[];
      for (final run in allRuns) {
        if (run.userId == _challenger0Id) {
          communityChallenges.add(run);
        } else {
          ongoingRuns.add(run);
        }
      }

      // Seed the display list with ongoing runs + one initial cycle of community challenges.
      _cycleCounter = 0;
      final display = [...ongoingRuns, ..._nextCycleBatch(communityChallenges)];

      emit(ExploreState.loaded(
        runs: display,
        fallbackPool: communityChallenges,
        cycleIndex: _cycleCounter,
      ));
    } catch (e) {
      emit(ExploreState.failure(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    ExploreLoadMoreRequested event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;
    if (current.fallbackPool.isEmpty) return;

    // Append the next cycle of fallback runs — pure client-side, zero latency.
    final nextBatch = _nextCycleBatch(current.fallbackPool);
    emit(ExploreState.loaded(
      runs: [...current.runs, ...nextBatch],
      fallbackPool: current.fallbackPool,
      cycleIndex: _cycleCounter,
      lastJoinedAt: current.lastJoinedAt,
    ));
  }

  Future<void> _onDismiss(
    ExploreRunDismissed event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;

    final run = current.runs.where((r) => r.runId == event.runId).firstOrNull;

    // Only fire server dismissal for real (non-cycled) runs.
    if (run != null && !event.runId.contains('_cycle')) {
      _runsRepository.dismissRun(run.runId);
    }

    // Remove from display (local-only for cycled cards — reappears next cycle).
    final updated = current.runs.where((r) => r.runId != event.runId).toList();
    emit(ExploreState.loaded(
      runs: updated,
      fallbackPool: current.fallbackPool,
      cycleIndex: current.cycleIndex,
      lastJoinedAt: current.lastJoinedAt,
    ));

    // Buffer: if running low, append more fallback content instantly.
    if (updated.length < 3 && current.fallbackPool.isNotEmpty) {
      add(const ExploreLoadMoreRequested());
    }
  }

  Future<void> _onJoin(
    ExploreRunJoined event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;

    // Find the run being joined so we can convert it to an ActiveRunEntity
    final exploreRun =
        current.runs.where((r) => r.runId == event.runId).firstOrNull;

    if (exploreRun != null) {
      final today = DateTime.now().toUtc();
      final startDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final activeRun = ActiveRunEntity(
        runId: 'temp-${exploreRun.challengeId}', // will be replaced by server ID
        challengeId: exploreRun.challengeId,
        challengeTitle: exploreRun.challengeTitle,
        challengeSlug: exploreRun.challengeSlug,
        currentStreak: 0,
        startDate: startDate,
        hasCheckedInToday: false,
        imageAsset: exploreRun.imageAsset,
        imageUrl: exploreRun.imageUrl,
      );

      try {
        await _runsRepository.addRun(activeRun);
      } on AlreadyParticipatingException {
        // User already has an active run for this challenge — keep the card in
        // the feed and inform them via a snackbar.
        emit(ExploreState.loaded(
          runs: current.runs,
          fallbackPool: current.fallbackPool,
          cycleIndex: current.cycleIndex,
          lastJoinedAt: current.lastJoinedAt,
          joinError: "You're already running this challenge!",
        ));
        return;
      } catch (e) {
        // ignore: avoid_print
        print('[ExploreBloc] addRun error: $e');
        // Keep the card in the feed so the user can retry.
        emit(ExploreState.loaded(
          runs: current.runs,
          fallbackPool: current.fallbackPool,
          cycleIndex: current.cycleIndex,
          lastJoinedAt: current.lastJoinedAt,
          joinError: "Couldn't join — please try again.",
        ));
        return;
      }
    }

    // Success: remove from Explore feed & signal join happened
    final updated = current.runs.where((r) => r.runId != event.runId).toList();
    emit(ExploreState.loaded(
      runs: updated,
      fallbackPool: current.fallbackPool,
      cycleIndex: current.cycleIndex,
      lastJoinedAt: DateTime.now(),
    ));

    // Buffer: if running low, append more fallback content instantly.
    if (updated.length < 3 && current.fallbackPool.isNotEmpty) {
      add(const ExploreLoadMoreRequested());
    }
  }

  Future<void> _onClearJoinError(
    ExploreClearJoinError event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;
    emit(ExploreState.loaded(
      runs: current.runs,
      fallbackPool: current.fallbackPool,
      cycleIndex: current.cycleIndex,
      lastJoinedAt: current.lastJoinedAt,
      // joinError omitted → defaults to null
    ));
  }

  void _onRunBetPlaced(
    ExploreRunBetPlaced event,
    Emitter<ExploreState> emit,
  ) {
    final current = state;
    if (current is! ExploreLoaded) return;

    final updatedRuns = current.runs.map((r) {
      if (r.runId == event.runId) {
        return ExploreRunEntity(
          runId: r.runId,
          challengeId: r.challengeId,
          challengeTitle: r.challengeTitle,
          challengeSlug: r.challengeSlug,
          userId: r.userId,
          username: r.username,
          avatarId: r.avatarId,
          currentStreak: r.currentStreak,
          imageUrl: r.imageUrl,
          imageAsset: r.imageAsset,
          recentBetCount: r.recentBetCount + 1,
          isCompleted: r.isCompleted,
        );
      }
      return r;
    }).toList();

    emit(ExploreState.loaded(
      runs: updatedRuns,
      fallbackPool: current.fallbackPool,
      cycleIndex: current.cycleIndex,
      lastJoinedAt: current.lastJoinedAt,
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a copy of [pool] with synthetic unique run IDs for this cycle.
  /// Each cycle increments [_cycleCounter] to ensure IDs never collide.
  List<ExploreRunEntity> _nextCycleBatch(List<ExploreRunEntity> pool) {
    _cycleCounter++;
    return pool.map((r) {
      return ExploreRunEntity(
        runId: '${r.runId}_cycle$_cycleCounter',
        challengeId: r.challengeId,
        challengeTitle: r.challengeTitle,
        challengeSlug: r.challengeSlug,
        userId: r.userId,
        username: r.username,
        avatarId: r.avatarId,
        currentStreak: r.currentStreak,
        imageUrl: r.imageUrl,
        imageAsset: r.imageAsset,
        recentBetCount: r.recentBetCount,
        isCompleted: r.isCompleted,
      );
    }).toList();
  }
}

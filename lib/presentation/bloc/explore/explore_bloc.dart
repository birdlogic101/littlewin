import 'package:flutter_bloc/flutter_bloc.dart';
import 'explore_event.dart';
import 'explore_state.dart';
import '../../../domain/entities/explore_run_entity.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../data/repositories/runs_repository.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final RunsRepository _runsRepository;

  ExploreBloc({required RunsRepository runsRepository})
      : _runsRepository = runsRepository,
        super(const ExploreState.initial()) {
    on<ExploreFetchRequested>(_onFetch);
    on<ExploreRunDismissed>(_onDismiss);
    on<ExploreRunJoined>(_onJoin);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    ExploreFetchRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreState.loading());
    try {
      // TODO: replace with real datasource call via use-case
      await Future.delayed(const Duration(milliseconds: 600));

      // Filter out any challenges the user has already joined
      final joinedIds =
          _runsRepository.activeRuns.map((r) => r.challengeId).toSet();
      final runs = _mockRuns()
          .where((r) => !joinedIds.contains(r.challengeId))
          .toList();

      emit(ExploreState.loaded(runs: runs, cursor: null, hasMore: false));
    } catch (e) {
      emit(ExploreState.failure(message: e.toString()));
    }
  }

  Future<void> _onDismiss(
    ExploreRunDismissed event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;

    final updated =
        current.runs.where((r) => r.runId != event.runId).toList();
    emit(ExploreState.loaded(
      runs: updated,
      cursor: current.cursor,
      hasMore: current.hasMore,
    ));

    // TODO: call dismiss use-case (fire-and-forget, do not block UI)
  }

  Future<void> _onJoin(
    ExploreRunJoined event,
    Emitter<ExploreState> emit,
  ) async {
    final current = state;
    if (current is! ExploreLoaded) return;

    // Find the run being joined so we can convert it to an ActiveRunEntity
    final exploreRun = current.runs
        .where((r) => r.runId == event.runId)
        .firstOrNull;

    if (exploreRun != null) {
      final today = DateTime.now().toUtc();
      final startDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Generate a unique run ID for the user's own run
      final newRunId = 'run-joined-${exploreRun.challengeId}-${today.millisecondsSinceEpoch}';

      final activeRun = ActiveRunEntity(
        runId: newRunId,
        challengeId: exploreRun.challengeId,
        challengeTitle: exploreRun.challengeTitle,
        challengeSlug: exploreRun.challengeSlug,
        currentStreak: 0,
        startDate: startDate,
        hasCheckedInToday: false,
        imageAsset: exploreRun.imageAsset,
        imageUrl: exploreRun.imageUrl,
      );

      await _runsRepository.addRun(activeRun);
    }

    // Remove from Explore feed & signal join happened
    final updated =
        current.runs.where((r) => r.runId != event.runId).toList();
    emit(ExploreState.loaded(
      runs: updated,
      cursor: current.cursor,
      hasMore: current.hasMore,
      lastJoinedAt: DateTime.now(),
    ));

    // TODO: call join use-case in Supabase (user's own run creation)
  }

  // ── Stub data (replaced when use-case + datasource are wired) ─────────────

  List<ExploreRunEntity> _mockRuns() => [
        const ExploreRunEntity(
          runId: 'run-1',
          challengeId: 'ch-02',
          challengeTitle: '16-Hour Fasting',
          challengeSlug: '16-hour-fasting',
          userId: 'user-1',
          username: 'elwilliam',
          avatarId: 1,
          currentStreak: 75,
          imageAsset: 'assets/pictures/challenge_16-hour-fasting.jpg',
        ),
        const ExploreRunEntity(
          runId: 'run-2',
          challengeId: 'ch-11',
          challengeTitle: '10,000 Steps',
          challengeSlug: '10000-steps',
          userId: 'user-2',
          username: 'marta.runs',
          avatarId: 3,
          currentStreak: 21,
          imageAsset: 'assets/pictures/challenge_10000-steps.jpg',
        ),
        const ExploreRunEntity(
          runId: 'run-3',
          challengeId: 'ch-03',
          challengeTitle: '1-Minute Cold Shower',
          challengeSlug: '1-minute-cold-shower',
          userId: 'user-3',
          username: 'jakobf',
          avatarId: 5,
          currentStreak: 9,
          imageAsset: 'assets/pictures/challenge_1-minute-cold-shower.jpg',
        ),
        const ExploreRunEntity(
          runId: 'run-4',
          challengeId: 'ch-04',
          challengeTitle: 'Zero Doomscroll',
          challengeSlug: 'zero-doomscroll',
          userId: 'user-4',
          username: 'quietmind',
          avatarId: 7,
          currentStreak: 33,
          imageAsset: 'assets/pictures/challenge_zero-doomscroll.jpg',
        ),
        const ExploreRunEntity(
          runId: 'run-5',
          challengeId: 'ch-07',
          challengeTitle: 'No Eating Out',
          challengeSlug: 'no-eating-out',
          userId: 'user-5',
          username: 'lena.cooks',
          avatarId: 2,
          currentStreak: 14,
          imageAsset: 'assets/pictures/challenge_no-eating-out.jpg',
          recentBetCount: 4,
        ),
        const ExploreRunEntity(
          runId: 'run-6',
          challengeId: 'ch-12',
          challengeTitle: 'Zero Alcohol',
          challengeSlug: 'zero-alcohol',
          userId: 'user-6',
          username: 'dryjan_paul',
          avatarId: 4,
          currentStreak: 56,
          imageAsset: 'assets/pictures/challenge_zero-alcohol.jpg',
          recentBetCount: 12,
        ),
        const ExploreRunEntity(
          runId: 'run-7',
          challengeId: 'ch-15',
          challengeTitle: '1-Page Journaling',
          challengeSlug: '1-page-journaling',
          userId: 'user-7',
          username: 'notepad_kai',
          avatarId: 6,
          currentStreak: 7,
          imageAsset: 'assets/pictures/challenge_1-page-journaling.jpg',
        ),
        const ExploreRunEntity(
          runId: 'run-8',
          challengeId: 'ch-01',
          challengeTitle: '10-Minute Workout',
          challengeSlug: '10-minute-workout',
          userId: 'user-8',
          username: 'thomas_fit',
          avatarId: 8,
          currentStreak: 42,
          imageAsset: 'assets/pictures/challenge_10-minute-workout.jpg',
          recentBetCount: 7,
        ),
      ];
}

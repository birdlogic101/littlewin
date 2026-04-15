import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'records_event.dart';
import 'records_state.dart';
import '../../../data/repositories/completed_runs_repository.dart';
import '../../../data/repositories/runs_repository.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../domain/entities/completed_run_entity.dart';

@injectable
class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  final CompletedRunsRepository _completedRunsRepository;
  final RunsRepository _runsRepository;
  StreamSubscription<dynamic>? _sub;

  RecordsBloc({
    required CompletedRunsRepository completedRunsRepository,
    required RunsRepository runsRepository,
  })  : _completedRunsRepository = completedRunsRepository,
        _runsRepository = runsRepository,
        super(const RecordsState.initial()) {
    on<RecordsFetchRequested>(_onFetch);
    on<RecordsRunsUpdated>(_onRunsUpdated);
    on<RecordsRestartChallengeRequested>(_onRestartChallenge);
  }

  Future<void> _onFetch(
    RecordsFetchRequested event,
    Emitter<RecordsState> emit,
  ) async {
    emit(const RecordsState.loading());
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(RecordsState.loaded(runs: _sortRuns(_completedRunsRepository.allRuns)));

      // Subscribe to new completions (day rollover → processCompletions)
      await _sub?.cancel();
      _sub = _completedRunsRepository.stream.listen((updatedRuns) {
        if (!isClosed) add(RecordsRunsUpdated(runs: updatedRuns));
      });
    } catch (e) {
      emit(RecordsState.failure(message: e.toString()));
    }
  }

  Future<void> _onRunsUpdated(
    RecordsRunsUpdated event,
    Emitter<RecordsState> emit,
  ) async {
    emit(RecordsState.loaded(runs: _sortRuns(event.runs)));
  }

  Future<void> _onRestartChallenge(
    RecordsRestartChallengeRequested event,
    Emitter<RecordsState> emit,
  ) async {
    final now = DateTime.now().toUtc();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final newRun = ActiveRunEntity(
      runId: 'run-${event.challengeSlug}-${now.millisecondsSinceEpoch}',
      challengeId: event.challengeId,
      challengeTitle: event.challengeTitle,
      challengeSlug: event.challengeSlug,
      currentStreak: 0,
      startDate: today,
      hasCheckedInToday: false,
      lastCheckinDay: null,
      imageAsset: event.imageAsset,
      imageUrl: event.imageUrl,
    );

    if (_runsRepository.isChallengeActive(event.challengeSlug)) {
      emit(const RecordsRestartAlreadyActive());
    } else {
      try {
        await _runsRepository.addRun(newRun);
        emit(const RecordsRestartSuccess());
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('ALREADY_JOINED')) {
          emit(const RecordsRestartAlreadyActive());
        } else {
          emit(RecordsState.failure(message: 'Could not restart challenge: $msg'));
        }
      }
    }

    // Switch back to loaded state so the UI doesn't stay in success forever
    emit(RecordsState.loaded(runs: _sortRuns(_completedRunsRepository.allRuns)));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<CompletedRunEntity> _sortRuns(List<CompletedRunEntity> runs) {
    return List<CompletedRunEntity>.from(runs)
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));
  }
}

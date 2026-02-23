import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';
import '../../../data/repositories/runs_repository.dart';

class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final RunsRepository _runsRepository;
  StreamSubscription<dynamic>? _runsSub;

  CheckinBloc({required RunsRepository runsRepository})
      : _runsRepository = runsRepository,
        super(const CheckinState.initial()) {
    on<CheckinFetchRequested>(_onFetch);
    on<CheckinPerformed>(_onCheckin);
    on<CheckinRunsUpdated>(_onRunsUpdated);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    CheckinFetchRequested event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinState.loading());
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(CheckinState.loaded(runs: _runsRepository.activeRuns));

      await _runsSub?.cancel();
      _runsSub = _runsRepository.stream.listen((updatedRuns) {
        if (!isClosed) add(CheckinRunsUpdated(runs: updatedRuns));
      });
    } catch (e) {
      emit(CheckinState.failure(message: e.toString()));
    }
  }

  Future<void> _onRunsUpdated(
    CheckinRunsUpdated event,
    Emitter<CheckinState> emit,
  ) async {
    emit(CheckinState.loaded(runs: event.runs));
  }

  Future<void> _onCheckin(
    CheckinPerformed event,
    Emitter<CheckinState> emit,
  ) async {
    final current = state;
    if (current is! CheckinLoaded) return;

    final run = _runsRepository.activeRuns
        .where((r) => r.runId == event.runId)
        .firstOrNull;
    if (run == null || run.hasCheckedInToday) return;

    // Compute today's UTC date string.
    final now = DateTime.now().toUtc();
    final todayUtc =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updated = run.copyWith(
      hasCheckedInToday: true,
      currentStreak: run.currentStreak + 1,
      lastCheckinDay: todayUtc, // ← required for processCompletions logic
    );

    // Optimistic UI update — emit immediately.
    final updatedRuns = _runsRepository.activeRuns.map((r) {
      return r.runId == event.runId ? updated : r;
    }).toList();
    emit(CheckinState.loaded(runs: updatedRuns));

    // Persist to shared repository (stream fires → CheckinRunsUpdated,
    // equatable suppresses a redundant rebuild since data is the same).
    _runsRepository.updateRun(updated);

    // TODO: call server-side check-in use-case
  }

  @override
  Future<void> close() {
    _runsSub?.cancel();
    return super.close();
  }
}

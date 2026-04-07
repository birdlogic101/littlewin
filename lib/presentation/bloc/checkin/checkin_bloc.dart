import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';
import '../../../data/repositories/runs_repository.dart';
import '../../../domain/entities/active_run_entity.dart';

@injectable
class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final RunsRepository _runsRepository;
  StreamSubscription<dynamic>? _runsSub;

  CheckinBloc({required RunsRepository runsRepository})
      : _runsRepository = runsRepository,
        super(const CheckinState.initial()) {
    on<CheckinFetchRequested>(_onFetch);
    on<CheckinPerformed>(_onCheckin);
    on<CheckinRunsUpdated>(_onRunsUpdated);
    on<DayRolloverDetected>(_onDayRollover);
    on<CheckinResolutionCleared>(_onResolutionCleared);
    on<CheckinRunBetPlaced>(_onRunBetPlaced);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    CheckinFetchRequested event,
    Emitter<CheckinState> emit,
  ) async {
    // ignore: avoid_print
    print('[CheckinBloc] _onFetch started');

    // Only flash the loading spinner on the very first load.
    // On subsequent fetches (midnight tick, bet-sheet close, etc.) keep the
    // current runs visible to avoid a disruptive spinner flash.
    if (state is! CheckinLoaded) {
      emit(const CheckinState.loading());
    }

    try {
      // Guard: if the UTC day rolled over while the app was in the background
      // (or killed + restored), any run with hasCheckedInToday=true but
      // lastCheckinDay != today must be reset — otherwise the UI would show
      // already-done runs as pending on the wrong day.
      _runsRepository.clearStaleCheckinFlags(_todayUtc());

      final runs = _runsRepository.activeRuns;
      // ignore: avoid_print
      print('[CheckinBloc] emitting loaded with ${runs.length} runs');
      emit(CheckinState.loaded(runs: runs));

      // Only (re-)subscribe if we don't already have an active subscription.
      // This prevents tearing down and rebuilding the stream on every re-fetch,
      // which could lose in-flight CheckinRunsUpdated events.
      if (_runsSub == null) {
        _runsSub = _runsRepository.stream.listen((updatedRuns) {
          if (!isClosed) add(CheckinRunsUpdated(runs: updatedRuns));
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[CheckinBloc] fetch error: $e');
      emit(CheckinState.failure(message: e.toString()));
    }
  }

  Future<void> _onRunsUpdated(
    CheckinRunsUpdated event,
    Emitter<CheckinState> emit,
  ) async {
    emit(CheckinState.loaded(runs: event.runs));
  }

  /// Called by [AppShell] after it runs [RunsRepository.processCompletions].
  /// Re-emits the now-updated active run list (missed runs have been removed,
  /// still-active runs have hasCheckedInToday reset).
  Future<void> _onDayRollover(
    DayRolloverDetected event,
    Emitter<CheckinState> emit,
  ) async {
    emit(CheckinState.loaded(runs: _runsRepository.activeRuns));
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
    // Guard: run must exist and must not already be checked in.
    // The repository's checkin() also guards, but we bail early here to
    // avoid the unnecessary async round-trip and optimistic emit.
    if (run == null || run.hasCheckedInToday) return;

    // 1. Trigger the update (synchronous part happens immediately)
    final checkinFuture = _runsRepository.checkin(event.runId);
    
    // 2. Emit the now-updated state immediately
    emit(CheckinState.loaded(runs: _runsRepository.activeRuns));

    try {
      // 3. Await the long-running RPC resolution
      final resolution = await checkinFuture;

      if (resolution != null && !isClosed) {
        // Emit with pendingResolution so CheckinScreen BlocListener can
        // show the BetWonModal. The run list comes from the stream update.
        emit(CheckinState.loaded(
          runs: _runsRepository.activeRuns,
          pendingResolution: resolution,
        ));
      }
    } catch (e) {
      // The repository already reverted the optimistic update and updated
      // the stream, so the UI will jump back to "Pending". 
      // We emit a failure state to show a snackbar/toast if needed.
      if (!isClosed) {
        emit(CheckinState.failure(message: e.toString()));
        // After showing the error, we should return to showing the current runs.
        emit(CheckinState.loaded(runs: _runsRepository.activeRuns));
      }
    }
  }

  Future<void> _onResolutionCleared(
    CheckinResolutionCleared event,
    Emitter<CheckinState> emit,
  ) async {
    final current = state;
    if (current is! CheckinLoaded) return;
    emit(CheckinState.loaded(runs: current.runs));
  }

  void _onRunBetPlaced(
    CheckinRunBetPlaced event,
    Emitter<CheckinState> emit,
  ) {
    final current = state;
    if (current is! CheckinLoaded) return;

    final run = current.runs.where((r) => r.runId == event.runId).firstOrNull;
    if (run == null) return;

    // Update the central repository so the change persists across refreshes
    final updatedRun = run.copyWith(betCount: run.betCount + 1);
    _runsRepository.updateRun(updatedRun);
    
    // Optimistic immediate update to the UI
    final newRuns = List<ActiveRunEntity>.from(current.runs);
    final idx = newRuns.indexWhere((r) => r.runId == event.runId);
    if (idx != -1) {
      newRuns[idx] = updatedRun;
    }
    emit(CheckinState.loaded(runs: newRuns));
  }

  @override
  Future<void> close() {
    _runsSub?.cancel();
    return super.close();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

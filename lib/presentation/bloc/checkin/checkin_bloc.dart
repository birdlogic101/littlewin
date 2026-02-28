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
    on<DayRolloverDetected>(_onDayRollover);
    on<CheckinResolutionCleared>(_onResolutionCleared);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    CheckinFetchRequested event,
    Emitter<CheckinState> emit,
  ) async {
    emit(const CheckinState.loading());
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      // Guard: if the UTC day rolled over while the app was in the background
      // (or killed + restored), any run with hasCheckedInToday=true but
      // lastCheckinDay != today must be reset — otherwise the UI would show
      // already-done runs as pending on the wrong day.
      _runsRepository.clearStaleCheckinFlags(_todayUtc());

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
    if (run == null || run.hasCheckedInToday) return;

    // Delegate to repository: handles optimistic update + Supabase RPC.
    // The stream subscription will update the run list; we separately
    // capture the resolution to show the modal if bets were triggered.
    final resolution = await _runsRepository.checkin(event.runId);

    if (resolution != null && !isClosed) {
      // Emit with pendingResolution so CheckinScreen BlocListener can
      // show the BetWonModal. The run list comes from the stream update.
      emit(CheckinState.loaded(
        runs: _runsRepository.activeRuns,
        pendingResolution: resolution,
      ));
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

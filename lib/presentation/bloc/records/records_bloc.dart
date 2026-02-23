import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'records_event.dart';
import 'records_state.dart';
import '../../../data/repositories/completed_runs_repository.dart';

class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  final CompletedRunsRepository _completedRunsRepository;
  StreamSubscription<dynamic>? _sub;

  RecordsBloc({required CompletedRunsRepository completedRunsRepository})
      : _completedRunsRepository = completedRunsRepository,
        super(const RecordsState.initial()) {
    on<RecordsFetchRequested>(_onFetch);
    on<RecordsRunsUpdated>(_onRunsUpdated);
  }

  Future<void> _onFetch(
    RecordsFetchRequested event,
    Emitter<RecordsState> emit,
  ) async {
    emit(const RecordsState.loading());
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      emit(RecordsState.loaded(runs: _completedRunsRepository.allRuns));

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
    emit(RecordsState.loaded(runs: event.runs));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

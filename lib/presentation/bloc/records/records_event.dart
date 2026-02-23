import 'package:equatable/equatable.dart';
import '../../../domain/entities/completed_run_entity.dart';

abstract class RecordsEvent extends Equatable {
  const RecordsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the current user's completed runs.
class RecordsFetchRequested extends RecordsEvent {
  const RecordsFetchRequested();
}

/// Internal event fired when [CompletedRunsRepository] stream emits a new list.
/// Keeps the Records screen in sync when a run is completed without re-fetching.
class RecordsRunsUpdated extends RecordsEvent {
  final List<CompletedRunEntity> runs;
  const RecordsRunsUpdated({required this.runs});

  @override
  List<Object?> get props => [runs];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/active_run_entity.dart';

abstract class CheckinEvent extends Equatable {
  const CheckinEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the current user's active runs.
class CheckinFetchRequested extends CheckinEvent {
  const CheckinFetchRequested();
}

/// Perform a check-in for a specific run.
class CheckinPerformed extends CheckinEvent {
  final String runId;
  const CheckinPerformed({required this.runId});

  @override
  List<Object?> get props => [runId];
}

/// Internal event fired when the [RunsRepository] stream emits a new list.
/// This keeps the Check-in screen in sync whenever a run is joined from Explore.
class CheckinRunsUpdated extends CheckinEvent {
  final List<ActiveRunEntity> runs;
  const CheckinRunsUpdated({required this.runs});

  @override
  List<Object?> get props => [runs];
}

/// Fired by [AppShell] after [RunsRepository.processCompletions] runs.
///
/// Instructs [CheckinBloc] to re-fetch the current run list from the
/// repository (which may now have fewer runs and reset daily flags).
class DayRolloverDetected extends CheckinEvent {
  const DayRolloverDetected();
}

/// Fired by [CheckinScreen] after [BetWonModal] has been shown and dismissed.
/// Clears [CheckinLoaded.pendingResolution] so the modal doesn't reappear.
class CheckinResolutionCleared extends CheckinEvent {
  const CheckinResolutionCleared();
}

import 'package:equatable/equatable.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) the explore feed from the top.
class ExploreFetchRequested extends ExploreEvent {
  const ExploreFetchRequested();
}

/// User tapped ✕ — hide this run for the dismissal duration.
class ExploreRunDismissed extends ExploreEvent {
  final String runId;
  const ExploreRunDismissed({required this.runId});

  @override
  List<Object?> get props => [runId];
}

/// User tapped "Join" — start a new run on this challenge.
class ExploreRunJoined extends ExploreEvent {
  final String runId;
  final String challengeId;
  const ExploreRunJoined({required this.runId, required this.challengeId});

  @override
  List<Object?> get props => [runId, challengeId];
}

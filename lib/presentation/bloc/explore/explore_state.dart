import 'package:equatable/equatable.dart';
import '../../../domain/entities/explore_run_entity.dart';

sealed class ExploreState extends Equatable {
  const ExploreState();

  const factory ExploreState.initial() = ExploreInitial;
  const factory ExploreState.loading() = ExploreLoading;
  const factory ExploreState.loaded({
    required List<ExploreRunEntity> runs,
    required List<ExploreRunEntity> fallbackPool,
    required int cycleIndex,
    DateTime? lastJoinedAt,
    String? joinError,
    String? joiningRunId,
  }) = ExploreLoaded;
  const factory ExploreState.failure({required String message}) =
      ExploreFailure;

  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  /// Runs currently displayed in the feed.
  final List<ExploreRunEntity> runs;

  /// Challenger0 runs saved for infinite cycling when real content runs out.
  final List<ExploreRunEntity> fallbackPool;

  /// Current position in the fallback pool cycle.
  final int cycleIndex;

  /// Set while the user is joining a run to show a loader and prevent duplicates.
  final String? joiningRunId;

  /// Timestamp of the last successful join.
  final DateTime? lastJoinedAt;

  /// Error message if a join request failed.
  final String? joinError;

  const ExploreLoaded({
    required this.runs,
    required this.fallbackPool,
    required this.cycleIndex,
    this.lastJoinedAt,
    this.joinError,
    this.joiningRunId,
  });

  ExploreLoaded copyWith({
    List<ExploreRunEntity>? runs,
    List<ExploreRunEntity>? fallbackPool,
    int? cycleIndex,
    DateTime? lastJoinedAt,
    String? joinError,
    Object? joiningRunId = _unset,
  }) {
    return ExploreLoaded(
      runs: runs ?? this.runs,
      fallbackPool: fallbackPool ?? this.fallbackPool,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      lastJoinedAt: lastJoinedAt ?? this.lastJoinedAt,
      joinError: joinError ?? this.joinError,
      joiningRunId: joiningRunId == _unset
          ? this.joiningRunId
          : joiningRunId as String?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props =>
      [runs, fallbackPool, cycleIndex, lastJoinedAt, joinError, joiningRunId];
}

class ExploreFailure extends ExploreState {
  final String message;
  const ExploreFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

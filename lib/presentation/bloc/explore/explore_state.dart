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

  /// Set to [DateTime.now()] each time the user joins a run.
  /// [home_page.dart] listens for changes to this field and switches to
  /// the Check-in tab automatically.
  final DateTime? lastJoinedAt;

  /// Non-null when an attempt to join failed — the screen shows a snackbar
  /// and the card is retained in the feed so the user can retry.
  final String? joinError;

  const ExploreLoaded({
    required this.runs,
    required this.fallbackPool,
    required this.cycleIndex,
    this.lastJoinedAt,
    this.joinError,
  });

  @override
  List<Object?> get props => [runs, fallbackPool, cycleIndex, lastJoinedAt, joinError];
}

class ExploreFailure extends ExploreState {
  final String message;
  const ExploreFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

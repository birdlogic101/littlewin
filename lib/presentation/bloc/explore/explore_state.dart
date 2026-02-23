import 'package:equatable/equatable.dart';
import '../../../domain/entities/explore_run_entity.dart';

sealed class ExploreState extends Equatable {
  const ExploreState();

  const factory ExploreState.initial() = ExploreInitial;
  const factory ExploreState.loading() = ExploreLoading;
  const factory ExploreState.loaded({
    required List<ExploreRunEntity> runs,
    required String? cursor,
    required bool hasMore,
    DateTime? lastJoinedAt,
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
  final List<ExploreRunEntity> runs;

  /// Cursor for the next page (null = first page or no more pages).
  final String? cursor;
  final bool hasMore;

  /// Set to [DateTime.now()] each time the user joins a run.
  /// [home_page.dart] listens for changes to this field and switches to
  /// the Check-in tab automatically.
  final DateTime? lastJoinedAt;

  const ExploreLoaded({
    required this.runs,
    required this.cursor,
    required this.hasMore,
    this.lastJoinedAt,
  });

  @override
  List<Object?> get props => [runs, cursor, hasMore, lastJoinedAt];
}

class ExploreFailure extends ExploreState {
  final String message;
  const ExploreFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

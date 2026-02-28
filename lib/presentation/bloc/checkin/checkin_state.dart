import 'package:equatable/equatable.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../domain/entities/bet_resolution_entity.dart';

sealed class CheckinState extends Equatable {
  const CheckinState();

  const factory CheckinState.initial() = CheckinInitial;
  const factory CheckinState.loading() = CheckinLoading;
  const factory CheckinState.loaded({
    required List<ActiveRunEntity> runs,
    BetResolutionEntity? pendingResolution,
  }) = CheckinLoaded;
  const factory CheckinState.failure({required String message}) =
      CheckinFailure;

  @override
  List<Object?> get props => [];
}

class CheckinInitial extends CheckinState {
  const CheckinInitial();
}

class CheckinLoading extends CheckinState {
  const CheckinLoading();
}

class CheckinLoaded extends CheckinState {
  final List<ActiveRunEntity> runs;

  /// Non-null when the last check-in triggered one or more won bets.
  /// The UI (CheckinScreen via BlocListener) uses this to show [BetWonModal].
  /// Reset to null after the modal is displayed by emitting a cleared state.
  final BetResolutionEntity? pendingResolution;

  const CheckinLoaded({
    required this.runs,
    this.pendingResolution,
  });

  @override
  List<Object?> get props => [runs, pendingResolution];
}

class CheckinFailure extends CheckinState {
  final String message;
  const CheckinFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

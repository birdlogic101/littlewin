import 'package:equatable/equatable.dart';
import '../../../domain/entities/active_run_entity.dart';

sealed class CheckinState extends Equatable {
  const CheckinState();

  const factory CheckinState.initial() = CheckinInitial;
  const factory CheckinState.loading() = CheckinLoading;
  const factory CheckinState.loaded({required List<ActiveRunEntity> runs}) =
      CheckinLoaded;
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
  const CheckinLoaded({required this.runs});

  @override
  List<Object?> get props => [runs];
}

class CheckinFailure extends CheckinState {
  final String message;
  const CheckinFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

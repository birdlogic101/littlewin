import 'package:equatable/equatable.dart';
import '../../../domain/entities/completed_run_entity.dart';

sealed class RecordsState extends Equatable {
  const RecordsState();

  const factory RecordsState.initial() = RecordsInitial;
  const factory RecordsState.loading() = RecordsLoading;
  const factory RecordsState.loaded({required List<CompletedRunEntity> runs}) =
      RecordsLoaded;
  const factory RecordsState.failure({required String message}) =
      RecordsFailure;

  @override
  List<Object?> get props => [];
}

class RecordsInitial extends RecordsState {
  const RecordsInitial();
}

class RecordsLoading extends RecordsState {
  const RecordsLoading();
}

class RecordsLoaded extends RecordsState {
  final List<CompletedRunEntity> runs;
  const RecordsLoaded({required this.runs});

  @override
  List<Object?> get props => [runs];
}

class RecordsFailure extends RecordsState {
  final String message;
  const RecordsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

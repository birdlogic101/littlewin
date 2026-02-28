import 'package:equatable/equatable.dart';
import '../../../domain/entities/challenge_creation_result.dart';

sealed class CreateChallengeState extends Equatable {
  const CreateChallengeState();
  @override
  List<Object?> get props => [];
}

class CreateChallengeInitial extends CreateChallengeState {
  const CreateChallengeInitial();
}

class CreateChallengeLoading extends CreateChallengeState {
  const CreateChallengeLoading();
}

class CreateChallengeSuccess extends CreateChallengeState {
  final ChallengeCreationResult result;
  const CreateChallengeSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class CreateChallengeFailure extends CreateChallengeState {
  final String message;
  const CreateChallengeFailure(this.message);
  @override
  List<Object?> get props => [message];
}

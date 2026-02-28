import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/create_challenge.dart';
import 'create_challenge_event.dart';
import 'create_challenge_state.dart';

class CreateChallengeBloc
    extends Bloc<CreateChallengeEvent, CreateChallengeState> {
  final CreateChallenge _createChallenge;

  CreateChallengeBloc({required CreateChallenge createChallenge})
      : _createChallenge = createChallenge,
        super(const CreateChallengeInitial()) {
    on<CreateChallengeSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    CreateChallengeSubmitted event,
    Emitter<CreateChallengeState> emit,
  ) async {
    emit(const CreateChallengeLoading());
    final result = await _createChallenge(CreateChallengeParams(
      title: event.title,
      description: event.description,
      visibility: event.visibility,
    ));
    result.fold(
      (failure) => emit(CreateChallengeFailure(failure.message)),
      (success) => emit(CreateChallengeSuccess(success)),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/runs_repository.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../domain/usecases/create_challenge.dart';
import 'create_challenge_event.dart';
import 'create_challenge_state.dart';

class CreateChallengeBloc
    extends Bloc<CreateChallengeEvent, CreateChallengeState> {
  final CreateChallenge _createChallenge;
  final RunsRepository _runsRepository;

  CreateChallengeBloc({
    required CreateChallenge createChallenge,
    required RunsRepository runsRepository,
  })  : _createChallenge = createChallenge,
        _runsRepository = runsRepository,
        super(const CreateChallengeInitial()) {
    on<CreateChallengeSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    CreateChallengeSubmitted event,
    Emitter<CreateChallengeState> emit,
  ) async {
    try {
      emit(const CreateChallengeLoading());
      final result = await _createChallenge(CreateChallengeParams(
        title: event.title,
        description: event.description,
        visibility: event.visibility,
        imageAsset: event.imageAsset,
      ));

      await result.fold(
        (failure) async => emit(CreateChallengeFailure(failure.message)),
        (success) async {
          // Inject the run into the repository so it's immediately available in the UI
          final today = DateTime.now().toUtc();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          _runsRepository.injectRun(ActiveRunEntity(
            runId: success.runId,
            challengeId: success.challengeId,
            challengeTitle: success.challengeTitle,
            challengeSlug: '', // Slug is used for joining, not required here
            currentStreak: 0,
            startDate: dateStr,
            hasCheckedInToday: false,
            imageAsset: event.imageAsset ?? 'assets/pictures/challenge_default_1080.jpg',
          ));

          emit(CreateChallengeSuccess(success));
        },
      );
    } catch (e) {
      emit(CreateChallengeFailure('Unexpected error: $e'));
    }
  }
}

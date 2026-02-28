import 'package:equatable/equatable.dart';

/// Returned by [CreateChallenge] usecase after a successful creation.
class ChallengeCreationResult extends Equatable {
  final String challengeId;
  final String runId;
  final String challengeTitle;

  const ChallengeCreationResult({
    required this.challengeId,
    required this.runId,
    required this.challengeTitle,
  });

  @override
  List<Object?> get props => [challengeId, runId, challengeTitle];
}

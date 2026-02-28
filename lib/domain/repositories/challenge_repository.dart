import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/challenge_creation_result.dart';

abstract class ChallengeRepository {
  Future<Either<Failure, ChallengeCreationResult>> createChallenge({
    required String title,
    required String description,
    required String visibility,
  });
}

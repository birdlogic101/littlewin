import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/challenge_creation_result.dart';
import '../../domain/entities/challenge_entity.dart';

abstract class ChallengeRepository {
  Future<Either<Failure, ChallengeCreationResult>> createChallenge({
    required String title,
    required String description,
    required String visibility,
    String? imageAsset,
  });

  Future<Either<Failure, List<ChallengeEntity>>> loadAll();
  Future<Either<Failure, ChallengeEntity?>> findById(String id);
}

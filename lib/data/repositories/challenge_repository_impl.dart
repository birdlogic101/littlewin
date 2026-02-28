import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/challenge_creation_result.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_remote_datasource.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final ChallengeRemoteDataSource _remote;

  ChallengeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ChallengeCreationResult>> createChallenge({
    required String title,
    required String description,
    required String visibility,
  }) async {
    try {
      final result = await _remote.createChallenge(
        title: title,
        description: description,
        visibility: visibility,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

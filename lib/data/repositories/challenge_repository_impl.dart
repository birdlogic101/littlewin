import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/challenge_creation_result.dart';
import '../../domain/entities/challenge_entity.dart';
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
    String? imageAsset,
  }) async {
    try {
      final result = await _remote.createChallenge(
        title: title,
        description: description,
        visibility: visibility,
        imageAsset: imageAsset,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> loadAll() async {
    try {
      final maps = await _remote.fetchAll();
      final entities = maps.map((map) => _mapToEntity(map)).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChallengeEntity?>> findById(String id) async {
    try {
      final map = await _remote.findById(id);
      if (map == null) return const Right(null);
      return Right(_mapToEntity(map));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  ChallengeEntity _mapToEntity(Map<String, dynamic> map) {
    return ChallengeEntity(
      id: map['id'] as String,
      slug: map['slug'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      imageAsset: map['image_asset'] as String? ?? 'assets/pictures/challenge_default_1080.jpg',
    );
  }
}

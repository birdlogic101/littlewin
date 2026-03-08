import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/challenge_creation_result.dart';
import '../repositories/challenge_repository.dart';

class CreateChallengeParams extends Equatable {
  final String title;
  final String description;
  final String visibility; // 'public' | 'private'
  final String? imageAsset;

  const CreateChallengeParams({
    required this.title,
    required this.description,
    required this.visibility,
    this.imageAsset,
  });

  @override
  List<Object?> get props => [title, description, visibility, imageAsset];
}

class CreateChallenge {
  final ChallengeRepository _repository;

  CreateChallenge(this._repository);

  Future<Either<Failure, ChallengeCreationResult>> call(
      CreateChallengeParams params) {
    return _repository.createChallenge(
      title: params.title,
      description: params.description,
      visibility: params.visibility,
      imageAsset: params.imageAsset,
    );
  }
}

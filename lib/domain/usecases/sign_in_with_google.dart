import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignInWithGoogle implements UseCase<UserEntity, GoogleSignInParams> {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(GoogleSignInParams params) {
    return repository.signInWithGoogle(anonymousIdToMerge: params.anonymousIdToMerge);
  }
}

class GoogleSignInParams extends Equatable {
  final String? anonymousIdToMerge;

  const GoogleSignInParams({this.anonymousIdToMerge});

  @override
  List<Object?> get props => [anonymousIdToMerge];
}

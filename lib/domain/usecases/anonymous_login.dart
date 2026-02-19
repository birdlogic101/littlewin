import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Signs the user in anonymously.
/// Per LW_brief: default onboarding starts anonymous; prompt to sign in
/// after the first meaningful action.
@lazySingleton
class AnonymousLogin implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  AnonymousLogin(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInAnonymously();
  }
}

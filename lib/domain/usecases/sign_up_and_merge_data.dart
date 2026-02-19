import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Upgrades an anonymous session to a full account (email or Google).
/// The anonymous user's data (runs, bets, etc.) is preserved via
/// the `anonymous_id` field on the users table.
/// Per LW_constraints §1: User has `anonymous_id` varchar(255) UNIQUE NULL.
@lazySingleton
class SignUpAndMergeData implements UseCase<UserEntity, MergeParams> {
  final AuthRepository repository;

  SignUpAndMergeData(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(MergeParams params) async {
    return await repository.signUpAndMerge(
      email: params.email,
      password: params.password,
      username: params.username,
    );
  }
}

class MergeParams extends Equatable {
  final String email;
  final String password;
  final String username;

  const MergeParams({
    required this.email,
    required this.password,
    required this.username,
  });

  @override
  List<Object> get props => [email, password, username];
}

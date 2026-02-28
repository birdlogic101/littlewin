import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateUsernameParams {
  final String username;
  const UpdateUsernameParams(this.username);
}

@injectable
class UpdateUsername implements UseCase<UserEntity, UpdateUsernameParams> {
  final AuthRepository _repository;

  UpdateUsername(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUsernameParams params) {
    return _repository.updateUsername(params.username);
  }
}

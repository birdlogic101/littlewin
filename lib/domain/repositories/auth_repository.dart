import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  /// Signs in anonymously. Creates a row in public.users with anonymous_id set.
  Future<Either<Failure, UserEntity>> signInAnonymously();

  /// Upgrades an anonymous session to a full account, preserving existing data.
  Future<Either<Failure, UserEntity>> signUpAndMerge({
    required String email,
    required String password,
    required String username,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Stream<UserEntity?> get userStream;
}


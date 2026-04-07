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

  Future<Either<Failure, UserEntity>> upgradeToPremium();
  
  /// Signs in with Google. If [anonymousIdToMerge] is provided, data from
  /// that account will be moved to the new Google account.
  Future<Either<Failure, UserEntity>> signInWithGoogle({String? anonymousIdToMerge});

  /// Explicitly merges data from an old anonymous account into the current one.
  Future<Either<Failure, UserEntity>> mergeAnonymousData(String anonymousId);

  Future<Either<Failure, UserEntity>> linkWithGoogle();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, UserEntity>> updateUsername(String username);

  Stream<UserEntity?> get userStream;
}


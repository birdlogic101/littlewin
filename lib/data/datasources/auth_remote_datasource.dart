import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  /// Signs in anonymously via Supabase anonymous auth.
  Future<UserModel> signInAnonymously();

  /// Upgrades an anonymous session to a full email account.
  Future<UserModel> signUpAndMerge({
    required String email,
    required String password,
    required String username,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get userStream;
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const ServerFailure('User is null');
      }
      return _getUserProfile(response.user!);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user == null) {
        throw const ServerFailure('User is null');
      }

      await supabaseClient.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'roles': ['basic'],
      });

      return UserModel(
        id: response.user!.id,
        email: email,
        username: username,
      );
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final response = await supabaseClient.auth.signInAnonymously();
      if (response.user == null) {
        throw const ServerFailure('Anonymous sign-in failed');
      }
      final anonId = response.user!.id;

      // Insert a minimal row in public.users; anonymous_id tracks the session.
      // username is left empty — will be set on merge/upgrade.
      await supabaseClient.from('users').upsert({
        'id': anonId,
        'username': 'anon_$anonId'.substring(0, 20), // temp unique username
        'anonymous_id': anonId,
        'roles': ['basic'],
      }, onConflict: 'id');

      final profile = await supabaseClient
          .from('users')
          .select()
          .eq('id', anonId)
          .single();

      return UserModel.fromSupabase(response.user!, profile);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signUpAndMerge({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Link the current anonymous session to an email account.
      // Supabase supports this via updateUser when the user is anonymous.
      final updateResponse = await supabaseClient.auth.updateUser(
        UserAttributes(email: email, password: password),
      );

      if (updateResponse.user == null) {
        throw const ServerFailure('Merge failed: user is null');
      }

      final uid = updateResponse.user!.id;

      // Update the public.users row: set real username, clear anonymous_id.
      await supabaseClient.from('users').update({
        'username': username,
        'email': email,
        'anonymous_id': null,
      }).eq('id', uid);

      final profile = await supabaseClient
          .from('users')
          .select()
          .eq('id', uid)
          .single();

      return UserModel.fromSupabase(updateResponse.user!, profile);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return null;
      return await _getUserProfile(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get userStream {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      try {
        return await _getUserProfile(user);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserModel> _getUserProfile(User user) async {
    final data = await supabaseClient
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    return UserModel.fromSupabase(user, data);
  }
}



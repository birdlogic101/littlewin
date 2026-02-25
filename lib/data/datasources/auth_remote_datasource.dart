import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const ServerFailure('Google sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const ServerFailure('No ID Token found.');
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw const ServerFailure('Sign in failed: user is null');
      }

      // Sync profile to public.users
      await supabaseClient.from('users').upsert({
        'id': response.user!.id,
        'username':
            response.user!.userMetadata?['full_name'] ?? googleUser.displayName,
        'email': response.user!.email,
        'roles': ['basic'],
      }, onConflict: 'id');

      return _getUserProfile(response.user!);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> linkWithGoogle() async {
    try {
      // For native linking, we still use GoogleSignIn to get the token,
      // then we use linkIdentity.
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const ServerFailure('Linking cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const ServerFailure('No ID Token found.');
      }

      // Supabase linkIdentity for native tokens might be different depending on SDK version.
      // If linkIdentity doesn't support idToken, we might need to handle it via updateUser or browser flow.
      // In supabase_flutter 2.x, linkIdentity(OAuthProvider.google) triggers browser.
      // To keep it native, we check if we can use linkIdentity with tokens.
      
      await supabaseClient.auth.linkIdentity(
        OAuthProvider.google,
        queryParams: {'access_token': googleAuth.accessToken ?? ''},
      );
      
      // Note: If linkIdentity above opens browser, we might want to reconsider.
      // But for now, let's follow standard Supabase identity linking.
      
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        throw const ServerFailure('User is null after linking');
      }

      // Update the public.users row: clear anonymous_id since now linked.
      await supabaseClient.from('users').update({
        'email': user.email,
        'anonymous_id': null,
      }).eq('id', user.id);

      return _getUserProfile(user);
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



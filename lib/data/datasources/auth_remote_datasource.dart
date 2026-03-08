import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/error/failures.dart';
import '../../core/utils/username_generator.dart';
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

  Future<UserModel> updateUsername(String username);

  Future<UserModel> upgradeToPremium();

  Future<UserModel> signInWithGoogle();

  Future<UserModel> linkWithGoogle();
  
  Future<void> updateFcmToken(String? token);

  Stream<UserModel?> get userStream;
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

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

      // Safety: if email confirmation is ever enabled, session will be null.
      if (response.session == null) {
        throw const ServerFailure(
          'Account created. Please check your email to confirm, then sign in.',
        );
      }

      // We rely on the Supabase trigger handle_new_user() to create the public.users profile.
      // We pause briefly or use a retry fetch (similar to Google auth) to return the profile.
      return await _getUserProfileWithRetry(response.user!);
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

      // Generate an absurd-but-memorable username for the anonymous user.
      // They can change it later from their profile.
      final generatedUsername = UsernameGenerator.generate();

      await supabaseClient.from('users').upsert({
        'id': anonId,
        'username': generatedUsername,
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
      print('AuthRemoteDataSource: Starting Google Sign-In');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('AuthRemoteDataSource: Google Sign-In cancelled by user');
        throw const ServerFailure('Google sign-in cancelled');
      }
      
      print('AuthRemoteDataSource: Requesting authentication tokens');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        print('AuthRemoteDataSource: No ID Token found');
        throw const ServerFailure('No ID Token found. Please ensure your Google Project is configured correctly.');
      }

      print('AuthRemoteDataSource: Signing in to Supabase with ID Token');
      final response = await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        print('AuthRemoteDataSource: Supabase sign-in failed, user is null');
        throw const ServerFailure('Sign in failed: user is null');
      }

      print('AuthRemoteDataSource: Google Sign-In successful for ${response.user!.email}');

      // The database trigger handle_new_user() takes care of creating the public.users row
      // using the metadata (full_name/email) from the provider.
      // We'll use a retry mechanism to wait for the trigger to finish.
      return await _getUserProfileWithRetry(response.user!);
    } on AuthException catch (e) {
      print('AuthRemoteDataSource: AuthException during Google Sign-In: ${e.message}');
      throw ServerFailure(e.message);
    } catch (e) {
      print('AuthRemoteDataSource: Unexpected error during Google Sign-In: $e');
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> linkWithGoogle() async {
    try {
      print('AuthRemoteDataSource: Starting Identity Linking with Google');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('AuthRemoteDataSource: Linking cancelled by user');
        throw const ServerFailure('Linking cancelled');
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        print('AuthRemoteDataSource: No access token found for linking');
        throw const ServerFailure('No access token found for linking.');
      }

      print('AuthRemoteDataSource: Linking Supabase identity');
      await supabaseClient.auth.linkIdentity(
        OAuthProvider.google,
        queryParams: {'access_token': accessToken},
      );
      
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        print('AuthRemoteDataSource: User is null after linking');
        throw const ServerFailure('User is null after linking');
      }

      print('AuthRemoteDataSource: Identity linked successfully for ${user.email}');

      // Refresh the profile with retry logic to ensure triggers finish
      return await _getUserProfileWithRetry(user);
    } on AuthException catch (e) {
      print('AuthRemoteDataSource: AuthException during linking: ${e.message}');
      throw ServerFailure(e.message);
    } catch (e) {
      print('AuthRemoteDataSource: Unexpected error during linking: $e');
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        supabaseClient.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> upgradeToPremium() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure('Not authenticated');

      // Add 'premium' to the user's roles array.
      await supabaseClient.rpc('grant_premium', params: {'uid': user.id});

      return _getUserProfile(user);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> updateUsername(String username) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw const ServerFailure('Not authenticated');

      await supabaseClient
          .from('users')
          .update({'username': username})
          .eq('id', user.id);

      return _getUserProfile(user);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
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

  @override
  Future<void> updateFcmToken(String? token) async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return;

      debugPrint('AuthRemoteDataSource: Updating FCM token for user ${user.id}');
      await supabaseClient
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('AuthRemoteDataSource: Failed to update FCM token: $e');
    }
  }

  /// Fetches the user profile with a retry mechanism to wait for backend triggers.
  Future<UserModel> _getUserProfileWithRetry(User user, {int maxRetries = 5}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        print('AuthRemoteDataSource: Fetching user profile (attempt $attempts)');
        return await _getUserProfile(user);
      } catch (e) {
        if (attempts >= maxRetries) {
          print('AuthRemoteDataSource: Profile fetch failed after $maxRetries attempts: $e');
          rethrow;
        }
        final delay = Duration(milliseconds: 500 * attempts);
        print('AuthRemoteDataSource: Profile not found yet, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
    throw const ServerFailure('Profile fetch timeout');
  }
}



import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/anonymous_login.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/link_with_google.dart';
import '../../../domain/usecases/sign_in.dart';
import '../../../domain/usecases/sign_in_with_google.dart';
import '../../../domain/usecases/sign_out.dart';
import '../../../domain/usecases/sign_up.dart';
import '../../../domain/usecases/update_username.dart';
import '../../../domain/usecases/upgrade_to_premium.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final AnonymousLogin _anonymousLogin;
  final SignInWithGoogle _signInWithGoogle;
  final LinkWithGoogle _linkWithGoogle;
  final UpdateUsername _updateUsername;
  final UpgradeToPremium _upgradeToPremium;

  AuthBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required AnonymousLogin anonymousLogin,
    required SignInWithGoogle signInWithGoogle,
    required LinkWithGoogle linkWithGoogle,
    required UpdateUsername updateUsername,
    required UpgradeToPremium upgradeToPremium,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _anonymousLogin = anonymousLogin,
        _signInWithGoogle = signInWithGoogle,
        _linkWithGoogle = linkWithGoogle,
        _updateUsername = updateUsername,
        _upgradeToPremium = upgradeToPremium,
        super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUpdateUsernameRequested>(_onUpdateUsernameRequested);
    on<AuthUpgradeToPremiumRequested>(_onUpgradeToPremiumRequested);
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getCurrentUser(NoParams());
    await result.fold(
      (failure) async {
        // If not logged in, try anonymous login
        final anonResult = await _anonymousLogin(NoParams());
        anonResult.fold(
          (f) => emit(AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user)),
        );
      },
      (user) async => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    // Check if current user is anonymous
    final currentUserResult = await _getCurrentUser(NoParams());
    final isAnonymous = currentUserResult.fold(
      (_) => false,
      (user) => user.isAnonymous,
    );

    if (isAnonymous) {
      // If anonymous, link the account
      final result = await _linkWithGoogle(NoParams());
      result.fold(
        (failure) => emit(AuthFailureState(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    } else {
      // If not anonymous (or no user), perform a fresh sign in
      final result = await _signInWithGoogle(NoParams());
      result.fold(
        (failure) => emit(AuthFailureState(failure.message)),
        (user) => emit(AuthAuthenticated(user)),
      );
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signUp(
      SignUpParams(
        email: event.email,
        password: event.password,
        username: event.username,
      ),
    );
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _signOut(NoParams());
    emit(AuthUnauthenticated());
  }

  Future<void> _onUpdateUsernameRequested(
    AuthUpdateUsernameRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _updateUsername(UpdateUsernameParams(event.username));
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onUpgradeToPremiumRequested(
    AuthUpgradeToPremiumRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _upgradeToPremium(NoParams());
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}

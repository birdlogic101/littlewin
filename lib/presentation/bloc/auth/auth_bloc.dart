import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/anonymous_login.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/sign_in.dart';
import '../../../domain/usecases/sign_in_with_google.dart';
import '../../../domain/usecases/sign_out.dart';
import '../../../domain/usecases/sign_up.dart';
import '../../../domain/usecases/sign_up_and_merge_data.dart';
import '../../../domain/usecases/update_username.dart';
import '../../../domain/usecases/upgrade_to_premium.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignUpAndMergeData _signUpAndMerge;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final AnonymousLogin _anonymousLogin;
  final SignInWithGoogle _signInWithGoogle;
  final UpdateUsername _updateUsername;
  final UpgradeToPremium _upgradeToPremium;

  AuthBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignUpAndMergeData signUpAndMerge,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required AnonymousLogin anonymousLogin,
    required SignInWithGoogle signInWithGoogle,
    required UpdateUsername updateUsername,
    required UpgradeToPremium upgradeToPremium,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signUpAndMerge = signUpAndMerge,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _anonymousLogin = anonymousLogin,
        _signInWithGoogle = signInWithGoogle,
        _updateUsername = updateUsername,
        _upgradeToPremium = upgradeToPremium,
        super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthAnonymousLoginRequested>(_onAnonymousLoginRequested);
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

    // Always use signInWithIdToken for native apps.
    // linkIdentity is browser-based and doesn't work on Android/iOS.
    // signInWithIdToken will replace the current session (anonymous or not).
    final result = await _signInWithGoogle(NoParams());
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
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

    // Check if the current session is anonymous — if so, upgrade instead of
    // creating a brand-new user so existing data (runs, bets) is preserved.
    final currentUserResult = await _getCurrentUser(NoParams());
    final isAnonymous = currentUserResult.fold(
      (_) => false,
      (user) => user.isAnonymous,
    );

    final Either<Failure, UserEntity> result;
    if (isAnonymous) {
      result = await _signUpAndMerge(MergeParams(
        email: event.email,
        password: event.password,
        username: event.username,
      ));
    } else {
      result = await _signUp(SignUpParams(
        email: event.email,
        password: event.password,
        username: event.username,
      ));
    }

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

  Future<void> _onAnonymousLoginRequested(
    AuthAnonymousLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _anonymousLogin(NoParams());
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
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

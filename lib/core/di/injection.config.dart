// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../data/datasources/auth_remote_datasource.dart' as _i1016;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/usecases/anonymous_login.dart' as _i251;
import '../../domain/usecases/get_current_user.dart' as _i906;
import '../../domain/usecases/link_with_google.dart' as _i373;
import '../../domain/usecases/sign_in.dart' as _i931;
import '../../domain/usecases/sign_in_with_google.dart' as _i202;
import '../../domain/usecases/sign_out.dart' as _i83;
import '../../domain/usecases/sign_up.dart' as _i877;
import '../../domain/usecases/sign_up_and_merge_data.dart' as _i225;
import '../../presentation/bloc/auth/auth_bloc.dart' as _i605;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i1016.AuthRemoteDataSource>(
      () => _i1016.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1073.AuthRepository>(
      () => _i895.AuthRepositoryImpl(gh<_i1016.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i251.AnonymousLogin>(
      () => _i251.AnonymousLogin(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i906.GetCurrentUser>(
      () => _i906.GetCurrentUser(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i373.LinkWithGoogle>(
      () => _i373.LinkWithGoogle(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i931.SignIn>(
      () => _i931.SignIn(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i202.SignInWithGoogle>(
      () => _i202.SignInWithGoogle(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i83.SignOut>(
      () => _i83.SignOut(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i877.SignUp>(
      () => _i877.SignUp(gh<_i1073.AuthRepository>()),
    );
    gh.lazySingleton<_i225.SignUpAndMergeData>(
      () => _i225.SignUpAndMergeData(gh<_i1073.AuthRepository>()),
    );
    gh.factory<_i605.AuthBloc>(
      () => _i605.AuthBloc(
        signIn: gh<_i931.SignIn>(),
        signUp: gh<_i877.SignUp>(),
        signOut: gh<_i83.SignOut>(),
        getCurrentUser: gh<_i906.GetCurrentUser>(),
        anonymousLogin: gh<_i251.AnonymousLogin>(),
        signInWithGoogle: gh<_i202.SignInWithGoogle>(),
        linkWithGoogle: gh<_i373.LinkWithGoogle>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

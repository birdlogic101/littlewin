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
import '../../data/datasources/bet_remote_datasource.dart' as _i1065;
import '../../data/datasources/notification_remote_datasource.dart' as _i906;
import '../../data/datasources/people_remote_datasource.dart' as _i999;
import '../../data/datasources/run_remote_datasource.dart' as _i22;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/bet_repository.dart' as _i155;
import '../../data/repositories/completed_runs_repository.dart' as _i72;
import '../../data/repositories/notification_repository.dart' as _i337;
import '../../data/repositories/people_repository.dart' as _i231;
import '../../data/repositories/runs_repository.dart' as _i123;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/usecases/anonymous_login.dart' as _i251;
import '../../domain/usecases/get_current_user.dart' as _i906;
import '../../domain/usecases/link_with_google.dart' as _i373;
import '../../domain/usecases/sign_in.dart' as _i931;
import '../../domain/usecases/sign_in_with_google.dart' as _i202;
import '../../domain/usecases/sign_out.dart' as _i83;
import '../../domain/usecases/sign_up.dart' as _i877;
import '../../domain/usecases/sign_up_and_merge_data.dart' as _i225;
import '../../domain/usecases/update_username.dart' as _i416;
import '../../domain/usecases/upgrade_to_premium.dart' as _i932;
import '../../presentation/bloc/auth/auth_bloc.dart' as _i605;
import '../../presentation/bloc/checkin/checkin_bloc.dart' as _i831;
import '../../presentation/bloc/explore/explore_bloc.dart' as _i1069;
import '../../presentation/bloc/notifications/notifications_bloc.dart'
    as _i1056;
import '../../presentation/bloc/people/people_bloc.dart' as _i792;
import '../../presentation/bloc/records/records_bloc.dart' as _i442;
import '../services/notification_service.dart' as _i941;
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
    gh.lazySingleton<_i72.CompletedRunsRepository>(
      () => _i72.CompletedRunsRepository(
        datasource: gh<_i22.RunRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i123.RunsRepository>(
      () => _i123.RunsRepository(datasource: gh<_i22.RunRemoteDataSource>()),
    );
    gh.factory<_i831.CheckinBloc>(
      () => _i831.CheckinBloc(runsRepository: gh<_i123.RunsRepository>()),
    );
    gh.factory<_i1069.ExploreBloc>(
      () => _i1069.ExploreBloc(runsRepository: gh<_i123.RunsRepository>()),
    );
    gh.lazySingleton<_i155.BetRepository>(
      () => _i155.BetRepository(datasource: gh<_i1065.BetRemoteDataSource>()),
    );
    gh.lazySingleton<_i1016.AuthRemoteDataSource>(
      () => _i1016.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i442.RecordsBloc>(
      () => _i442.RecordsBloc(
        completedRunsRepository: gh<_i72.CompletedRunsRepository>(),
        runsRepository: gh<_i123.RunsRepository>(),
      ),
    );
    gh.lazySingleton<_i1065.BetRemoteDataSource>(
      () => _i1065.BetRemoteDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i906.NotificationRemoteDataSource>(
      () => _i906.NotificationRemoteDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i999.PeopleRemoteDataSource>(
      () => _i999.PeopleRemoteDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i22.RunRemoteDataSource>(
      () => _i22.RunRemoteDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1073.AuthRepository>(
      () => _i895.AuthRepositoryImpl(gh<_i1016.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i231.PeopleRepository>(
      () => _i231.PeopleRepository(
        datasource: gh<_i999.PeopleRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i337.NotificationRepository>(
      () => _i337.NotificationRepository(
        gh<_i906.NotificationRemoteDataSource>(),
      ),
    );
    gh.factory<_i792.PeopleBloc>(
      () => _i792.PeopleBloc(repository: gh<_i231.PeopleRepository>()),
    );
    gh.lazySingleton<_i941.NotificationService>(
      () => _i941.NotificationService(gh<_i1016.AuthRemoteDataSource>()),
    );
    gh.factory<_i1056.NotificationsBloc>(
      () => _i1056.NotificationsBloc(gh<_i337.NotificationRepository>()),
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
    gh.factory<_i416.UpdateUsername>(
      () => _i416.UpdateUsername(gh<_i1073.AuthRepository>()),
    );
    gh.factory<_i932.UpgradeToPremium>(
      () => _i932.UpgradeToPremium(gh<_i1073.AuthRepository>()),
    );
    gh.factory<_i605.AuthBloc>(
      () => _i605.AuthBloc(
        signIn: gh<_i931.SignIn>(),
        signUp: gh<_i877.SignUp>(),
        signUpAndMerge: gh<_i225.SignUpAndMergeData>(),
        signOut: gh<_i83.SignOut>(),
        getCurrentUser: gh<_i906.GetCurrentUser>(),
        anonymousLogin: gh<_i251.AnonymousLogin>(),
        signInWithGoogle: gh<_i202.SignInWithGoogle>(),
        updateUsername: gh<_i416.UpdateUsername>(),
        upgradeToPremium: gh<_i932.UpgradeToPremium>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

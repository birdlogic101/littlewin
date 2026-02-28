import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/explore/explore_bloc.dart';
import '../bloc/explore/explore_state.dart';
import '../bloc/checkin/checkin_bloc.dart';
import '../bloc/checkin/checkin_event.dart';
import '../bloc/records/records_bloc.dart';
import '../bloc/people/people_bloc.dart';
import '../widgets/lw_app_bar.dart';
import '../widgets/lw_icon.dart';
import 'explore/explore_screen.dart';
import 'checkin/checkin_screen.dart';
import 'records/records_screen.dart';
import 'people/people_screen.dart';
import '../widgets/profile_drawer.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/runs_repository.dart';
import '../../data/repositories/completed_runs_repository.dart';
import '../../data/repositories/bet_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/datasources/run_remote_datasource.dart';
import '../../data/datasources/bet_remote_datasource.dart';
import '../../data/datasources/people_remote_datasource.dart';
import '../widgets/create_challenge_sheet.dart';

/// Root shell of the app.
///
/// - Creates and owns the two shared repositories ([RunsRepository] and
///   [CompletedRunsRepository]) so all blocs share the same data.
/// - Implements [WidgetsBindingObserver] to detect UTC day rollovers on
///   foreground resume and trigger [RunsRepository.processCompletions].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // TODO(future): move repository initialization into AuthBloc once the
  // auth analyzer errors in auth_remote_datasource.dart are resolved.
  // For now, AppShell owns initialization to route around those issues.
  late final RunRemoteDataSource _runDatasource;
  late final RunsRepository _runsRepository;
  late final CompletedRunsRepository _completedRunsRepository;
  late final BetRepository _betRepository;
  late final PeopleRepository _peopleRepository;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// The UTC day string seen on last foreground event / cold start.
  late String _lastSeenUtcDay;

  @override
  void initState() {
    super.initState();
    _lastSeenUtcDay = _todayUtc();

    // Wire Supabase datasource into the shared repositories.
    // SupabaseClient is a singleton — safe to access directly here.
    _runDatasource = RunRemoteDataSource(Supabase.instance.client);
    _runsRepository = RunsRepository(datasource: _runDatasource);
    _completedRunsRepository =
        CompletedRunsRepository(datasource: _runDatasource);
    _betRepository = BetRepository(
      datasource: BetRemoteDataSource(Supabase.instance.client),
    );
    _peopleRepository = PeopleRepository(
      datasource: PeopleRemoteDataSource(Supabase.instance.client),
    );

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Server-side settlement first (handles inactive users).
      //    Fire-and-forget; non-fatal errors are swallowed in datasource.
      await _runDatasource.settleRuns(_lastSeenUtcDay);

      // 2. Load real run data from Supabase into in-memory repos.
      //    processCompletions is called inside initialize() after the fetch.
      await Future.wait([
        _runsRepository.initialize(_completedRunsRepository),
        _completedRunsRepository.initialize(),
      ]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runsRepository.dispose();
    _completedRunsRepository.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDayRollover();
    }
  }

  void _checkDayRollover() {
    final today = _todayUtc();
    if (today != _lastSeenUtcDay) {
      _lastSeenUtcDay = today;
      _runsRepository.processCompletions(today, _completedRunsRepository);
      // Tell CheckinBloc to reload the run list now that completions are done.
      if (context.mounted) {
        context.read<CheckinBloc>().add(const DayRolloverDetected());
      }
    }
  }

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ExploreBloc>(
          create: (_) => ExploreBloc(runsRepository: _runsRepository),
        ),
        BlocProvider<CheckinBloc>(
          create: (_) => CheckinBloc(runsRepository: _runsRepository),
        ),
        BlocProvider<RecordsBloc>(
          create: (_) => RecordsBloc(
              completedRunsRepository: _completedRunsRepository),
        ),
        BlocProvider<PeopleBloc>(
          create: (_) => PeopleBloc(repository: _peopleRepository),
        ),
      ],
      child: BlocListener<ExploreBloc, ExploreState>(
        listenWhen: (prev, curr) {
          if (curr is! ExploreLoaded) return false;
          if (prev is! ExploreLoaded) return curr.lastJoinedAt != null;
          return curr.lastJoinedAt != prev.lastJoinedAt &&
              curr.lastJoinedAt != null;
        },
        listener: (context, state) => _switchTab(1),
        child: Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          drawer: const ProfileDrawer(),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isPremium = authState is AuthAuthenticated
                    ? authState.user.isPremium
                    : false;
                return LwAppBar(
                  // Always show the + button; premium users get create flow,
                  // non-premium get the upgrade dialog.
                  showCreate: true,
                  notificationCount: 0,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationsTap: () {},
                  onCreateTap: isPremium
                      ? () => CreateChallengeSheet.show(
                            context,
                            betRepository: _betRepository,
                          )
                      : () => ProfileDrawer.showUpgradeDialog(context),
                );
              },
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              ExploreScreen(betRepository: _betRepository),
              CheckinScreen(betRepository: _betRepository),
              const RecordsScreen(),
              PeopleScreen(peopleRepository: _peopleRepository),
            ],
          ),
          bottomNavigationBar: _LwBottomNav(
            currentIndex: _currentIndex,
            onTap: _switchTab,
            navColor: lw.navBackground,
            activeColor: lw.navIconActive,
            inactiveColor: lw.navIconInactive,
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _LwBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color navColor;
  final Color activeColor;
  final Color inactiveColor;

  const _LwBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.navColor,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LWComponents.bottomNav.height +
          MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: navColor,
        border: Border(
          top: BorderSide(
            color: LWThemeExtension.of(context).borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              svgName: 'nav_home',
              label: 'Explore',
              isActive: currentIndex == 0,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onTap(0),
            ),
            _NavItem(
              svgName: 'nav_checkin',
              label: 'Check-in',
              isActive: currentIndex == 1,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onTap(1),
            ),
            _NavItem(
              svgName: 'nav_scores',
              label: 'Records',
              isActive: currentIndex == 2,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onTap(2),
            ),
            _NavItem(
              svgName: 'nav_people',
              label: 'People',
              isActive: currentIndex == 3,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String svgName;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.svgName,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LwIcon(
                svgName,
                size: LWComponents.bottomNav.iconSize,
                color: isActive ? activeColor : inactiveColor,
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: LWComponents.bottomNav.dotSize,
                    height: LWComponents.bottomNav.dotSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

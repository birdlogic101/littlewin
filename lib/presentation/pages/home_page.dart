import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/explore/explore_bloc.dart';
import '../bloc/explore/explore_state.dart';
import '../bloc/explore/explore_event.dart';
import '../bloc/checkin/checkin_bloc.dart';
import '../bloc/checkin/checkin_event.dart';
import '../bloc/checkin/checkin_state.dart';
import '../bloc/records/records_bloc.dart';
import '../bloc/records/records_event.dart';
import '../bloc/people/people_bloc.dart';
import '../bloc/people/people_event.dart';
import '../bloc/notifications/notifications_bloc.dart';
import '../bloc/notifications/notifications_state.dart';
import '../bloc/notifications/notifications_event.dart';
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
import '../widgets/create_challenge_sheet.dart';
import '../widgets/add_person_sheet.dart';
import '../widgets/bet_won_modal.dart';
import '../widgets/notifications_drawer.dart';
import '../../core/di/injection.dart';

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
  // Repositories
  late final RunsRepository _runsRepository;
  late final CompletedRunsRepository _completedRunsRepository;
  late final BetRepository _betRepository;
  late final PeopleRepository _peopleRepository;
  
  // Blocs
  late final ExploreBloc _exploreBloc;
  late final CheckinBloc _checkinBloc;
  late final RecordsBloc _recordsBloc;
  late final PeopleBloc _peopleBloc;
  late final NotificationsBloc _notificationsBloc;
  
  /// Timer to check for UTC day rollover even if the app stays in foreground.
  Timer? _rolloverTimer;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  /// The UTC day string seen on last foreground event / cold start.
  late String _lastSeenUtcDay;

  /// Tracks when the user last visited the Check-in tab to clear the badge.
  DateTime? _lastCheckinVisit;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [AppShell] initState started');
    _lastSeenUtcDay = _todayUtc();

    // Resolve dependencies from getIt
    _runsRepository = getIt<RunsRepository>();
    _completedRunsRepository = getIt<CompletedRunsRepository>();
    _betRepository = getIt<BetRepository>();
    _peopleRepository = getIt<PeopleRepository>();

    _exploreBloc = getIt<ExploreBloc>();
    _checkinBloc = getIt<CheckinBloc>();
    _recordsBloc = getIt<RecordsBloc>();
    _peopleBloc = getIt<PeopleBloc>();
    _notificationsBloc = getIt<NotificationsBloc>();

    WidgetsBinding.instance.addObserver(this);
    
    // Check for rollover every 30 seconds
    _rolloverTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDayRollover());    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🚀 [AppShell] postFrameCallback: triggering initial settle and fetch');
      await _settleAndRefresh();

      // 4. Check for won bets (Bettor Celebration)
      try {
        final unseenWins = await _betRepository.getUnseenWonBets();
        if (unseenWins.isNotEmpty && mounted) {
          debugPrint('🎉 [AppShell] Found ${unseenWins.length} unseen wins!');
          for (final win in unseenWins) {
            await BetWonModal.show(context, resolution: win, isBettorView: true);
          }
          final allBetIds = unseenWins.expand((w) => w.wonBets.map((b) => b.betId)).toList();
          await _betRepository.acknowledgeWonBets(allBetIds);
        }
      } catch (e) {
        debugPrint('⚠️ [AppShell] Bettor celebration error: $e');
      }
    });

    _startUtcTimer();
  }

  // ── UTC Timer ──────────────────────────────────────────────────────────────
  Timer? _utcTimer;
  String _utcTimeLeft = '';

  void _startUtcTimer() {
    _updateUtcTime();
    _utcTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateUtcTime());
  }

  void _updateUtcTime() {
    final now = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);

    if (diff.isNegative || diff.inSeconds == 0) {
      if (_utcTimeLeft != '00:00:00') {
        _utcTimeLeft = '00:00:00';
        if (mounted) {
          _checkinBloc.add(const CheckinFetchRequested());
        }
      }
    } else {
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      if (mounted) {
        setState(() => _utcTimeLeft = '$h:$m:$s');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rolloverTimer?.cancel();
    _utcTimer?.cancel();
    _exploreBloc.close();
    _checkinBloc.close();
    _recordsBloc.close();
    _peopleBloc.close();
    _notificationsBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🚀 [AppShell] app resumed');
      _checkDayRollover();
    }
  }

  Future<void> _checkDayRollover() async {
    final today = _todayUtc();
    if (today != _lastSeenUtcDay) {
      debugPrint('🚀 [AppShell] day rollover detected: $today');
      _lastSeenUtcDay = today;
      await _settleAndRefresh();
    }
  }

  /// Calls the server-side settlement RPC and then notifies all BLoCs to
  /// refresh their data. This ensures "missed" runs complete and UI stays in sync.
  Future<void> _settleAndRefresh() async {
    // 1. Settle on server
    try {
      debugPrint('🚀 [AppShell] settling runs for $_lastSeenUtcDay...');
      await getIt<RunRemoteDataSource>()
          .settleRuns(_lastSeenUtcDay)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ [AppShell] settleRuns error: $e');
    }

    // 2. Initialize Repositories (syncs local state with DB)
    try {
      await Future.wait([
        _runsRepository.initialize(_completedRunsRepository),
        _completedRunsRepository.initialize(),
      ]).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ [AppShell] repo initialization error: $e');
    }

    // 3. Trigger refreshing of all visible/active segments
    debugPrint('🚀 [AppShell] triggering global Bloc refreshes');
    if (mounted) {
      _checkinBloc.add(const CheckinFetchRequested());
      _exploreBloc.add(const ExploreFetchRequested());
      _recordsBloc.add(const RecordsFetchRequested());
      _peopleBloc.add(const PeopleFetchRequested());
      _notificationsBloc.add(const NotificationsFetchRequested());
    }
  }

  static String _todayUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      _lastCheckinVisit = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _exploreBloc),
        BlocProvider.value(value: _checkinBloc),
        BlocProvider.value(value: _recordsBloc),
        BlocProvider.value(value: _peopleBloc),
        BlocProvider.value(value: _notificationsBloc),
      ],
      child: Builder(
        builder: (innerContext) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final currentNav = _navigatorKeys[_currentIndex].currentState;
              if (currentNav != null && currentNav.canPop()) {
                currentNav.pop();
              } else {
                if (_currentIndex != 0) {
                  _switchTab(0);
                } else {
                  SystemNavigator.pop();
                }
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: lw.backgroundApp,
              extendBodyBehindAppBar: false,
              drawer: const ProfileDrawer(),
              endDrawer: const NotificationsDrawer(),
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  Navigator(
                    key: _navigatorKeys[0],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => ExploreScreen(
                        betRepository: _betRepository,
                        runsRepository: _runsRepository,
                        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onOpenNotifications: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ),
                  ),
                  Navigator(
                    key: _navigatorKeys[1],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => CheckinScreen(
                        betRepository: _betRepository,
                        utcTimeLeft: _utcTimeLeft,
                      ),
                    ),
                  ),
                  Navigator(
                    key: _navigatorKeys[2],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => RecordsScreen(
                        betRepository: _betRepository,
                        onChallengeRestarted: () => _switchTab(1),
                      ),
                    ),
                  ),
                  Navigator(
                    key: _navigatorKeys[3],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => PeopleScreen(
                        peopleRepository: _peopleRepository,
                        runsRepository: _runsRepository,
                        betRepository: _betRepository,
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _LwBottomNav(
                currentIndex: _currentIndex,
                onTap: _switchTab,
                lastCheckinVisit: _lastCheckinVisit,
                navColor: lw.navBackground,
                activeColor: lw.contentPrimary,
                inactiveColor: lw.contentSecondary.withOpacity(0.5),
              ),
            ),
          );
        },
      ),
    );
}
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _LwBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final DateTime? lastCheckinVisit;
  final Color navColor;
  final Color activeColor;
  final Color inactiveColor;

  const _LwBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.lastCheckinVisit,
    required this.navColor,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0 +
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
            BlocBuilder<ExploreBloc, ExploreState>(
              builder: (context, exploreState) {
                return BlocBuilder<CheckinBloc, CheckinState>(
                  builder: (context, checkinState) {
                    final hasPending = checkinState is CheckinLoaded &&
                        checkinState.runs.any((r) => !r.hasCheckedInToday);

                    // Show dot badge if a new join happened since last visit
                    bool showJoinBadge = false;
                    if (exploreState is ExploreLoaded &&
                        exploreState.lastJoinedAt != null) {
                      if (lastCheckinVisit == null ||
                          exploreState.lastJoinedAt!
                              .isAfter(lastCheckinVisit!)) {
                        showJoinBadge = true;
                      }
                    }

                    return _PulseIcon(
                      isPulsing: hasPending && currentIndex != 1,
                      child: _NavItem(
                        svgName: 'nav_checkin',
                        label: 'Check-in',
                        isActive: currentIndex == 1,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTap(1),
                        showBadge: showJoinBadge && currentIndex != 1,
                      ),
                    );
                  },
                );
              },
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
  final bool showBadge;

  const _NavItem({
    required this.svgName,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.showBadge = false,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  LwIcon(
                    svgName,
                    size: LWComponents.bottomNav.iconSize,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: LWThemeExtension.of(context).feedbackNegative,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: LWThemeExtension.of(context).navBackground,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final Widget child;
  final bool isPulsing;

  const _PulseIcon({required this.child, required this.isPulsing});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _controller.stop();
      _controller.animateTo(0, duration: LWDuration.normal);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPulsing ? _scale.value : 1.0,
          child: Opacity(
            opacity: widget.isPulsing ? _opacity.value : 1.0,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final int index;
  final LWThemeExtension lw;

  const _AppBarTitle({
    required this.index,
    required this.lw,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = switch (index) {
      1 => 'Check in',
      2 => 'Records',
      3 => 'People',
      _ => '',
    };

    return Text(
      titleText,
      style: LWTypography.largeNoneRegular.copyWith(
        color: LWColors.inkBase,
      ),
    );
  }
}

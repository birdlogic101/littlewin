import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/explore/explore_bloc.dart';
import '../../bloc/explore/explore_event.dart';
import '../../bloc/explore/explore_state.dart';
import '../../widgets/explore_run_card.dart';
import '../../widgets/run_bets_sheet.dart';
import '../../../core/theme/design_system.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/notifications/notifications_bloc.dart';
import '../../bloc/notifications/notifications_state.dart';
import '../../widgets/lw_app_bar.dart';
import '../../widgets/create_challenge_sheet.dart';
import '../../widgets/profile_drawer.dart';
import '../../../domain/entities/people_user_entity.dart';
import '../people/view_user_screen.dart';
import '../../../data/repositories/runs_repository.dart';

/// The Explore screen — home tab of the app.
///
/// Displays a vertical PageView of full-bleed run cards.
/// The user swipes up/down to browse, taps Join or Dismiss on each card.
class ExploreScreen extends StatefulWidget {
  final BetRepository betRepository;
  final RunsRepository runsRepository;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenNotifications;

  const ExploreScreen({
    super.key,
    required this.betRepository,
    required this.runsRepository,
    required this.onOpenMenu,
    required this.onOpenNotifications,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<ExploreBloc>().add(const ExploreFetchRequested());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (!_pageController.hasClients) return;
    final next = (_pageController.page?.round() ?? 0) + 1;
    _pageController.animateToPage(
      next,
      duration: LWDuration.slow,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExploreBloc, ExploreState>(
      // Only react to listener when joinError changes.
      listenWhen: (prev, next) =>
          next is ExploreLoaded && next.joinError != null,
      listener: (context, state) {
        if (state is ExploreLoaded && state.joinError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.joinError!),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          // Clear the error so it doesn't re-fire on the next rebuild.
          context.read<ExploreBloc>().add(const ExploreClearJoinError());
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isPremium = authState is AuthAuthenticated
                    ? authState.user.isPremium
                    : false;

                return BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, notificationState) {
                    final count = notificationState is NotificationsLoaded
                        ? notificationState.unreadCount
                        : 0;

                    return LwAppBar(
                      showCreate: true,
                      notificationCount: count,
                      onMenuTap: widget.onOpenMenu,
                      onNotificationsTap: widget.onOpenNotifications,
                      onCreateTap: isPremium
                          ? () => CreateChallengeSheet.show(
                                context,
                                betRepository: widget.betRepository,
                              )
                          : () => ProfileDrawer.showUpgradeDialog(context),
                    );
                  },
                );
              },
            ),
          ),
          body: switch (state) {
            ExploreInitial() || ExploreLoading() => const _LoadingView(),
            ExploreFailure(:final message) => _ErrorView(message: message),
            ExploreLoaded(:final runs) => runs.isEmpty
              ? const _EmptyView()
              : PageView.builder(
                  controller: _pageController
                ..addListener(() {
                  if (!_pageController.hasClients) return;
                  final threshold = runs.length - 2;
                  if (_pageController.page! >= threshold) {
                    context
                        .read<ExploreBloc>()
                        .add(const ExploreLoadMoreRequested());
                  }
                }),
              scrollDirection: Axis.vertical,
              itemCount: runs.length,
              itemBuilder: (context, index) {
                final run = runs[index];
                return ExploreRunCard(
                  key: ValueKey(run.runId),
                  run: run,
                  isJoining: state.joiningRunId == run.runId,
                  onDismiss: () {
                    context
                        .read<ExploreBloc>()
                        .add(ExploreRunDismissed(runId: run.runId));
                    _nextCard();
                  },
                  onJoin: () {
                    context.read<ExploreBloc>().add(ExploreRunJoined(
                          runId: run.runId,
                          challengeId: run.challengeId,
                        ));
                    _nextCard();
                  },
                  onBetTap: () => RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: run.username,
                    isSelfBet: false,
                    startInPlaceMode: run.recentBetCount == 0,
                    betRepository: widget.betRepository,
                    onBetPlaced: () => context
                        .read<ExploreBloc>()
                        .add(ExploreRunBetPlaced(runId: run.runId)),
                  ),
                  onAvatarTap: () {
                    final tempUser = PeopleUserEntity(
                      userId: run.userId,
                      username: run.username,
                      avatarId: run.avatarId,
                      isFollowing: false,
                      ongoingRunCount: 0,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ViewUserScreen(
                          user: tempUser,
                          runsRepository: widget.runsRepository,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          },
        );
      },
    );
  }
}

// ── Supporting views ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return ColoredBox(
      color: lw.backgroundApp,
      child: Center(
        child: CircularProgressIndicator(
          color: lw.brandPrimary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return ColoredBox(
      color: lw.backgroundApp,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LWSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_rounded,
                  size: 64, color: lw.contentSecondary),
              const SizedBox(height: LWSpacing.lg),
              Text(
                'No runs to explore right now.',
                style: LWTypography.regularNormalRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LWSpacing.sm),
              Text(
                'Check back soon — new challenges are added every day.',
                style: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return ColoredBox(
      color: lw.backgroundApp,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LWSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48, color: lw.contentSecondary),
              const SizedBox(height: LWSpacing.lg),
              Text(
                'Could not load runs.',
                style: LWTypography.regularNormalBold
                    .copyWith(color: lw.contentPrimary),
              ),
              const SizedBox(height: LWSpacing.sm),
              Text(
                message,
                style: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: LWSpacing.xl),
              ElevatedButton(
                onPressed: () => context
                    .read<ExploreBloc>()
                    .add(const ExploreFetchRequested()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

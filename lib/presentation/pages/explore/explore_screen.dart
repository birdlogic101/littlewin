import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/explore/explore_bloc.dart';
import '../../bloc/explore/explore_event.dart';
import '../../bloc/explore/explore_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/explore_run_card.dart';
import '../../widgets/run_bets_sheet.dart';
import '../../widgets/self_bet_invite_dialog.dart';
import '../../../core/theme/design_system.dart';
import '../../../data/repositories/bet_repository.dart';

/// The Explore screen — home tab of the app.
///
/// Displays a vertical PageView of full-bleed run cards.
/// The user swipes up/down to browse, taps Join or Dismiss on each card.
class ExploreScreen extends StatefulWidget {
  final BetRepository betRepository;
  const ExploreScreen({super.key, required this.betRepository});

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
      listenWhen: (prev, curr) {
        if (curr is! ExploreLoaded) return false;
        if (prev is! ExploreLoaded) return curr.lastJoinedAt != null;
        return curr.lastJoinedAt != prev.lastJoinedAt &&
            curr.lastJoinedAt != null;
      },
      listener: (context, state) {
        if (state is! ExploreLoaded) return;
        // Find the most recently joined run from active runs
        // (it was added by ExploreBloc._onJoin using a temp ID)
        final authState = context.read<AuthBloc>().state;
        final username = authState is AuthAuthenticated
            ? authState.user.username
            : null;
        // The bloc removes the joined run from the feed; the last run in the
        // feed before removal was the one joined. We use a heuristic:
        // show the dialog with the challenge data we know from the event.
        // For now we fire with a placeholder — the real runId comes from
        // the Supabase join (wired in the next iteration).
        // We do still have access to the run that was added to activeRuns.
        // Use a generic invite since we don't have the exact runId here yet.
        SelfBetInviteDialog.show(
          context,
          runId: '', // empty = bet sheet handles gracefully
          challengeTitle: 'your new challenge',
          currentStreak: 0,
          betRepository: widget.betRepository,
          username: username,
        );
      },
      builder: (context, state) {
        return switch (state) {
          ExploreInitial() || ExploreLoading() => const _LoadingView(),
          ExploreFailure(:final message) => _ErrorView(message: message),
          ExploreLoaded(:final runs) when runs.isEmpty => const _EmptyView(),
          ExploreLoaded(:final runs) => PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: runs.length,
              itemBuilder: (context, index) {
                final run = runs[index];
                return ExploreRunCard(
                  key: ValueKey(run.runId),
                  run: run,
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
                  },
                  onBetTap: () => RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: run.username,
                    isSelfBet: false,
                    betRepository: widget.betRepository,
                  ),
                );
              },
            ),
        };
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

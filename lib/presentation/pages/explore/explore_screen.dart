import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/explore/explore_bloc.dart';
import '../../bloc/explore/explore_event.dart';
import '../../bloc/explore/explore_state.dart';
import '../../widgets/explore_run_card.dart';
import '../../../core/theme/design_system.dart';

/// The Explore screen — home tab of the app.
///
/// Displays a vertical PageView of full-bleed run cards.
/// The user swipes up/down to browse, taps Join or Dismiss on each card.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

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
    return BlocBuilder<ExploreBloc, ExploreState>(
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

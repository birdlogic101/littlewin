import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/checkin/checkin_bloc.dart';
import '../../bloc/checkin/checkin_event.dart';
import '../../bloc/checkin/checkin_state.dart';
import '../../widgets/lw_page_header.dart';
import '../../widgets/run_active_card.dart';
import '../../widgets/run_bets_sheet.dart';
import '../../widgets/bet_won_modal.dart';
import '../../../core/theme/design_system.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../data/repositories/bet_repository.dart';

/// The Check-in tab — shows the user's active runs with one-tap check-in.
///
/// **Pending** tab: runs not yet checked in today.
/// **Done** tab: runs already checked in today.
///
/// When a run is checked in it briefly shows a green "done" state in the
/// Pending list (so the user sees the confirmation), then gracefully
/// disappears into Done after [_exitDuration].
class CheckinScreen extends StatefulWidget {
  final BetRepository betRepository;
  const CheckinScreen({super.key, required this.betRepository});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  static const _exitDuration = Duration(milliseconds: 600);

  bool _showPending = true;

  /// Run IDs that were just checked in and are in their exit-animation window.
  /// While a run is in this set it is still shown in Pending (with green state)
  /// then disappears after [_exitDuration].
  final _exiting = <String>{};

  @override
  void initState() {
    super.initState();
    context.read<CheckinBloc>().add(const CheckinFetchRequested());
  }

  void _handleCheckin(BuildContext ctx, ActiveRunEntity run) {
    if (_exiting.contains(run.runId)) return; // debounce double-tap

    setState(() => _exiting.add(run.runId));

    // Fire the BLoC event (emits immediately → button turns green)
    ctx.read<CheckinBloc>().add(CheckinPerformed(runId: run.runId));

    // After exit window, card naturally disappears from Pending filter
    Future.delayed(_exitDuration, () {
      if (mounted) setState(() => _exiting.remove(run.runId));
    });

    // Confirmation SnackBar
    final streak = run.currentStreak + 1;
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  'Checked in! ${run.challengeTitle} · $streak day streak',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LWRadius.sm)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocConsumer<CheckinBloc, CheckinState>(
      // Show BetWonModal whenever a check-in triggers won bets.
      listenWhen: (prev, curr) =>
          curr is CheckinLoaded && curr.pendingResolution != null,
      listener: (ctx, state) async {
        if (state is! CheckinLoaded || state.pendingResolution == null) return;
        final resolution = state.pendingResolution!;
        // Clear the resolution flag before awaiting so it won't re-trigger.
        ctx.read<CheckinBloc>().add(const CheckinResolutionCleared());
        await BetWonModal.show(ctx, resolution: resolution);
      },
      builder: (context, state) {
        return ColoredBox(
          color: lw.backgroundApp,
          child: switch (state) {
            CheckinInitial() || CheckinLoading() => const _LoadingView(),
            CheckinFailure(:final message) => _ErrorView(message: message),
            CheckinLoaded(:final runs) => _LoadedView(
                runs: runs,
                showPending: _showPending,
                exiting: _exiting,
                onSegmentChanged: (v) => setState(() => _showPending = v),
                onCheckin: (run) => _handleCheckin(context, run),
                betRepository: widget.betRepository,
              ),
          },
        );
      },
    );
  }
}

// ── Loaded view ───────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final List<ActiveRunEntity> runs;
  final bool showPending;
  final Set<String> exiting;
  final ValueChanged<bool> onSegmentChanged;
  final ValueChanged<ActiveRunEntity> onCheckin;
  final BetRepository betRepository;

  const _LoadedView({
    required this.runs,
    required this.showPending,
    required this.exiting,
    required this.onSegmentChanged,
    required this.onCheckin,
    required this.betRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Pending = not yet checked in today, OR in the 600ms exit window.
    // Done = already checked in today (and not in exit window).
    final filtered = showPending
        ? runs
            .where((r) => !r.hasCheckedInToday || exiting.contains(r.runId))
            .toList()
        : runs.where((r) => r.hasCheckedInToday).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LwPageHeader(title: 'Check in'),
              _SegmentedToggle(
                showPending: showPending,
                onChanged: onSegmentChanged,
              ),
              const SizedBox(height: LWSpacing.sm),
            ],
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptySegmentView(pending: showPending),
          )
        else
          SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final run = filtered[index];
              // Show green "done" state during exit window even if BLoC already
              // has hasCheckedInToday=true (it does — we emitted immediately).
              final isDoneState =
                  run.hasCheckedInToday || exiting.contains(run.runId);
              return _AnimatedCard(
                key: ValueKey(run.runId),
                isExiting: exiting.contains(run.runId) && run.hasCheckedInToday,
                exitDuration: const Duration(milliseconds: 400),
                child: RunActiveCard(
                  run: run,
                  forceDone: isDoneState,
                  onCheckin: isDoneState ? null : () => onCheckin(run),
                  onBetTap: () => RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: 'you',
                    isSelfBet: true,
                    betRepository: betRepository,
                  ),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: LWSpacing.xxl)),
      ],
    );
  }
}

// ── Animated card wrapper (fade + collapse on exit) ───────────────────────────

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final bool isExiting;
  final Duration exitDuration;

  const _AnimatedCard({
    super.key,
    required this.child,
    required this.isExiting,
    required this.exitDuration,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _size;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.exitDuration);
    _size = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _opacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void didUpdateWidget(_AnimatedCard old) {
    super.didUpdateWidget(old);
    if (widget.isExiting && !old.isExiting) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SizeTransition(
        sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_size),
        child: widget.child,
      ),
    );
  }
}

// ── Segmented toggle ──────────────────────────────────────────────────────────

class _SegmentedToggle extends StatelessWidget {
  final bool showPending;
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({required this.showPending, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Row(
      children: [
        _ToggleTab(
          label: 'Pending',
          isActive: showPending,
          activeColor: lw.contentPrimary,
          inactiveColor: lw.contentSecondary,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: LWSpacing.xxl),
        _ToggleTab(
          label: 'Done',
          isActive: !showPending,
          activeColor: lw.contentPrimary,
          inactiveColor: lw.contentSecondary,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 180),
        style: (isActive
                ? LWTypography.regularNormalBold
                : LWTypography.regularNormalRegular)
            .copyWith(color: isActive ? activeColor : inactiveColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: isActive ? 40 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting views ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child:
          CircularProgressIndicator(color: lw.brandPrimary, strokeWidth: 2.5),
    );
  }
}

class _EmptySegmentView extends StatelessWidget {
  final bool pending;
  const _EmptySegmentView({required this.pending});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pending
                  ? Icons.check_circle_outline_rounded
                  : Icons.hourglass_empty_rounded,
              size: 64,
              color: lw.contentSecondary,
            ),
            const SizedBox(height: LWSpacing.lg),
            Text(
              pending ? 'All done for today! 🎉' : 'Nothing checked in yet',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              pending
                  ? 'Explore new challenges to keep the streak going.'
                  : 'Tap the check-in button on a pending run.',
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text('Could not load runs.',
                style: LWTypography.regularNormalBold
                    .copyWith(color: lw.contentPrimary)),
            const SizedBox(height: LWSpacing.sm),
            Text(message,
                style: LWTypography.smallNormalRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: LWSpacing.xl),
            ElevatedButton(
              onPressed: () => context
                  .read<CheckinBloc>()
                  .add(const CheckinFetchRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

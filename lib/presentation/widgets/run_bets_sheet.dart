import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bet_entity.dart';
import '../bloc/bet/bet_bloc.dart';
import '../bloc/bet/bet_event.dart';
import '../bloc/bet/bet_state.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/bet_repository.dart';
import 'place_bet_modal.dart';

/// Step 1 of the bet flow: a bottom sheet showing all existing bets on a run,
/// plus a "Place bet" button that opens [PlaceBetModal].
class RunBetsSheet extends StatelessWidget {
  final String runId;
  final int currentStreak;
  final String username;
  final bool isSelfBet;
  final BetRepository betRepository;

  const RunBetsSheet._({
    required this.runId,
    required this.currentStreak,
    required this.username,
    required this.isSelfBet,
    required this.betRepository,
  });

  /// Opens the run-bets sheet. Call this everywhere instead of
  /// navigating to the widget directly.
  static Future<void> show(
    BuildContext context, {
    required String runId,
    required int currentStreak,
    required String username,
    required bool isSelfBet,
    required BetRepository betRepository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RunBetsSheet._(
        runId: runId,
        currentStreak: currentStreak,
        username: username,
        isSelfBet: isSelfBet,
        betRepository: betRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BetBloc>(
      create: (_) => BetBloc(repository: betRepository)
        ..add(BetSheetOpened(
          runId: runId,
          currentStreak: currentStreak,
          isSelfBet: isSelfBet,
        )),
      child: _BetsSheetContent(
        username: username,
        isSelfBet: isSelfBet,
        currentStreak: currentStreak,
        runId: runId,
        betRepository: betRepository,
      ),
    );
  }
}

// ── Sheet content ─────────────────────────────────────────────────────────────

class _BetsSheetContent extends StatelessWidget {
  final String username;
  final bool isSelfBet;
  final int currentStreak;
  final String runId;
  final BetRepository betRepository;

  const _BetsSheetContent({
    required this.username,
    required this.isSelfBet,
    required this.currentStreak,
    required this.runId,
    required this.betRepository,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: lw.backgroundApp,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: LWSpacing.sm),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: lw.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LWSpacing.xl, LWSpacing.lg, LWSpacing.xl, LWSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelfBet ? 'Your bets' : '@$username\'s bets',
                    style: LWTypography.title4
                        .copyWith(color: lw.contentPrimary),
                  ),
                  Text(
                    'Current streak: $currentStreak days',
                    style: LWTypography.smallNormalRegular
                        .copyWith(color: lw.contentSecondary),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Bets list
            Expanded(
              child: BlocBuilder<BetBloc, BetState>(
                builder: (context, state) {
                  if (state is BetLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: lw.brandPrimary, strokeWidth: 2.5),
                    );
                  }
                  if (state is! BetReady) return const SizedBox.shrink();

                  if (state.existingBets.isEmpty) {
                    return _EmptyBetsView(isSelfBet: isSelfBet);
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: LWSpacing.md),
                    itemCount: state.existingBets.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: LWSpacing.xl),
                    itemBuilder: (_, i) =>
                        _BetRow(bet: state.existingBets[i]),
                  );
                },
              ),
            ),

            // ── Place bet CTA
            Padding(
              padding: EdgeInsets.fromLTRB(
                LWSpacing.xl,
                LWSpacing.sm,
                LWSpacing.xl,
                MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: LWComponents.button.height,
                child: ElevatedButton(
                  onPressed: () async {
                    final placed = await PlaceBetModal.show(
                      // ignore: use_build_context_synchronously
                      context,
                      runId: runId,
                      currentStreak: currentStreak,
                      username: username,
                      isSelfBet: isSelfBet,
                      betRepository: betRepository,
                    );
                    if (placed) {
                      // Reload bets on the open sheet after a successful place
                      if (context.mounted) {
                        context.read<BetBloc>().add(BetSheetOpened(
                              runId: runId,
                              currentStreak: currentStreak,
                              isSelfBet: isSelfBet,
                            ));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LWColors.skyBase,
                    foregroundColor: Colors.white,
                    elevation: LWElevation.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.pill)),
                    textStyle: LWComponents.button.labelStyle,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Place bet'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bet row ───────────────────────────────────────────────────────────────────

class _BetRow extends StatelessWidget {
  final BetEntity bet;
  const _BetRow({required this.bet});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    final statusColor = switch (bet.status) {
      BetStatus.won => LWColors.positiveBase,
      BetStatus.lost => LWColors.energyBase,
      BetStatus.pending => lw.contentSecondary,
    };

    final statusLabel = switch (bet.status) {
      BetStatus.won => 'Won',
      BetStatus.lost => 'Lost',
      BetStatus.pending => 'Pending',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LWSpacing.xl, vertical: LWSpacing.md),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lw.borderSubtle,
            ),
            child: Icon(Icons.person_rounded,
                size: 20, color: lw.contentSecondary),
          ),
          const SizedBox(width: LWSpacing.md),

          // Name + stake
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bet.bettorUsername ?? 'Someone',
                  style: LWTypography.regularNormalBold
                      .copyWith(color: lw.contentPrimary),
                ),
                if (bet.stakeTitle != null)
                  Text(
                    bet.stakeTitle!,
                    style: LWTypography.smallNormalRegular
                        .copyWith(color: lw.contentSecondary),
                  ),
              ],
            ),
          ),

          // Target streak + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 14, color: Color(0xFFFFAB40)),
                  const SizedBox(width: 3),
                  Text(
                    '${bet.targetStreak}',
                    style: LWTypography.regularNormalBold
                        .copyWith(color: lw.contentPrimary),
                  ),
                ],
              ),
              Text(
                statusLabel,
                style: LWTypography.smallNormalRegular
                    .copyWith(color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBetsView extends StatelessWidget {
  final bool isSelfBet;
  const _EmptyBetsView({required this.isSelfBet});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded,
                size: 56, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text(
              isSelfBet ? 'No self-bets yet' : 'No bets yet',
              style:
                  LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              isSelfBet
                  ? 'Add a bet to hold yourself accountable!'
                  : 'Be the first to bet on this run!',
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

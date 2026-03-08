import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bet_entity.dart';
import '../../domain/entities/stake_entity.dart';
import '../bloc/bet/bet_bloc.dart';
import '../bloc/bet/bet_event.dart';
import '../bloc/bet/bet_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/bet_repository.dart';
import 'custom_stake_sheet.dart';
import 'lw_icon.dart';
import 'lw_button.dart';
import 'profile_drawer.dart';

enum _BetViewMode { list, place }

/// A unified "Bet Experience" bottom sheet.
/// 
/// Shows existing bets by default, and allows placing a new bet via 
/// a smooth internal transition. Occupies ~90% of screen height to 
/// give content more breathing room.
class RunBetsSheet extends StatelessWidget {
  final String runId;
  final int currentStreak;
  final String username;
  final bool isSelfBet;
  final bool startInPlaceMode;
  final BetRepository betRepository;
  final VoidCallback? onBetPlaced;

  const RunBetsSheet._({
    required this.runId,
    required this.currentStreak,
    required this.username,
    required this.isSelfBet,
    required this.startInPlaceMode,
    required this.betRepository,
    this.onBetPlaced,
  });

  static Future<void> show(
    BuildContext context, {
    required String runId,
    required int currentStreak,
    required String username,
    required bool isSelfBet,
    bool startInPlaceMode = false,
    required BetRepository betRepository,
    VoidCallback? onBetPlaced,
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
        startInPlaceMode: startInPlaceMode,
        betRepository: betRepository,
        onBetPlaced: onBetPlaced,
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
      child: _BetExperienceContent(
        username: username,
        isSelfBet: isSelfBet,
        currentStreak: currentStreak,
        runId: runId,
        startInPlaceMode: startInPlaceMode,
        onBetPlaced: onBetPlaced,
      ),
    );
  }
}

class _BetExperienceContent extends StatefulWidget {
  final String username;
  final bool isSelfBet;
  final int currentStreak;
  final String runId;
  final bool startInPlaceMode;
  final VoidCallback? onBetPlaced;

  const _BetExperienceContent({
    required this.username,
    required this.isSelfBet,
    required this.currentStreak,
    required this.runId,
    required this.startInPlaceMode,
    this.onBetPlaced,
  });

  @override
  State<_BetExperienceContent> createState() => _BetExperienceContentState();
}

class _BetExperienceContentState extends State<_BetExperienceContent> {
  late _BetViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.startInPlaceMode ? _BetViewMode.place : _BetViewMode.list;
  }

  void _toggleView() {
    setState(() {
      _viewMode = _viewMode == _BetViewMode.list
          ? _BetViewMode.place
          : _BetViewMode.list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocListener<BetBloc, BetState>(
      listenWhen: (_, curr) =>
          curr is BetReady && curr.submitStatus == BetSubmitStatus.success,
      listener: (ctx, _) {
        // After successful bet, show snackbar and go back to list
        ScaffoldMessenger.of(ctx)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Row(children: [
              const Text('⭐ ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  'Bet placed! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ]),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LWRadius.sm)),
          ));
        
        // Notify the parent about the successful bet
        widget.onBetPlaced?.call();

        // Close the whole modal and return to previous screen
        Navigator.pop(ctx);
      },
      child: Container(
        decoration: BoxDecoration(
          color: lw.backgroundApp,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(LWRadius.lg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle for aesthetics
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: LWSpacing.md),
              decoration: BoxDecoration(
                color: lw.interactiveDisabled,
                borderRadius: LWRadius.full,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                        position: offsetAnimation, child: child),
                  );
                },
                child: _viewMode == _BetViewMode.list
                    ? _BetsListView(
                        username: widget.username,
                        isSelfBet: widget.isSelfBet,
                        currentStreak: widget.currentStreak,
                        onPlaceBetTap: _toggleView,
                      )
                    : _PlaceBetView(
                        username: widget.username,
                        isSelfBet: widget.isSelfBet,
                        onBackTap: _toggleView,
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

// ── List View ─────────────────────────────────────────────────────────────────

class _BetsListView extends StatelessWidget {
  final String username;
  final bool isSelfBet;
  final int currentStreak;
  final VoidCallback onPlaceBetTap;

  const _BetsListView({
    required this.username,
    required this.isSelfBet,
    required this.currentStreak,
    required this.onPlaceBetTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Column(
      key: const ValueKey('list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LWSpacing.xl, LWSpacing.lg, LWSpacing.xl, LWSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bets',
                      style: LWTypography.title4
                          .copyWith(color: lw.contentPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Current streak: $currentStreak days',
                      style: LWTypography.smallNormalRegular
                          .copyWith(color: lw.contentSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close_rounded,
                    color: lw.contentSecondary, size: 24),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Bets list
        BlocBuilder<BetBloc, BetState>(
          builder: (context, state) {
            if (state is BetLoading) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                      color: LWColors.skyBase, strokeWidth: 2.5),
                ),
              );
            }
            if (state is! BetReady) return const SizedBox.shrink();

            if (state.existingBets.isEmpty) {
              return _EmptyBetsView(isSelfBet: isSelfBet);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: LWSpacing.md),
              itemCount: state.existingBets.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: LWSpacing.xl),
              itemBuilder: (_, i) => _BetRow(bet: state.existingBets[i]),
            );
          },
        ),

        // ── Place bet CTA
        Padding(
          padding: EdgeInsets.fromLTRB(
            LWSpacing.xl,
            LWSpacing.sm,
            LWSpacing.xl,
            MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
          ),
          child: LwButton.primary(
            label: 'Place bet',
            onPressed: onPlaceBetTap,
            icon: const Icon(Icons.star_rounded, size: 18),
            width: double.infinity,
          ),
        ),
      ],
    );
  }
}

// ── Place View ────────────────────────────────────────────────────────────────

class _PlaceBetView extends StatelessWidget {
  final String username;
  final bool isSelfBet;
  final VoidCallback onBackTap;

  const _PlaceBetView({
    required this.username,
    required this.isSelfBet,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocBuilder<BetBloc, BetState>(
      key: const ValueKey('place'),
      builder: (context, state) {
        if (state is! BetReady) return const SizedBox.shrink();

        return Column(
          children: [

            // ── Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LWSpacing.lg, LWSpacing.md, LWSpacing.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBackTap,
                    icon: Icon(Icons.arrow_back_rounded,
                        color: lw.contentPrimary, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    'Place bet',
                    style: LWTypography.regularNormalBold
                        .copyWith(color: lw.contentPrimary),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance back button
                ],
              ),
            ),

            const SizedBox(height: LWSpacing.lg),

            // ── Streak selector (fixed at top, compact)
            _StreakSelector(state: state),

            const SizedBox(height: 32),

            // ── Reward / stake section (fills remaining space, scrolls internally)
            Expanded(
              child: _StakeSection(state: state),
            ),

            // ── Error message
            if (state.submitStatus == BetSubmitStatus.error &&
                state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: LWSpacing.xl, vertical: LWSpacing.xs),
                child: Text(
                  state.errorMessage!,
                  style: LWTypography.smallNormalRegular
                      .copyWith(color: LWColors.energyBase),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Place bet button
            Padding(
              padding: EdgeInsets.fromLTRB(
                LWSpacing.xl,
                LWSpacing.sm,
                LWSpacing.xl,
                MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
              ),
              child: _PlaceBetButton(state: state),
            ),
          ],
        );
      },
    );
  }
}

// ── Streak selector ───────────────────────────────────────────────────────────

class _StreakSelector extends StatelessWidget {
  final BetReady state;
  const _StreakSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              icon: Icons.keyboard_double_arrow_left_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(-10)),
            ),
            const SizedBox(width: LWSpacing.xs),
            _AdjustButton(
              icon: Icons.chevron_left_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(-1)),
            ),
            const SizedBox(width: LWSpacing.md),
            _StreakCircle(value: state.targetStreak),
            const SizedBox(width: LWSpacing.md),
            _AdjustButton(
              icon: Icons.chevron_right_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(1)),
            ),
            const SizedBox(width: LWSpacing.xs),
            _AdjustButton(
              icon: Icons.keyboard_double_arrow_right_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(10)),
            ),
          ],
        ),
        const SizedBox(height: LWSpacing.xs),
        Text(
          'Target streak (days)',
          style: LWTypography.smallNormalRegular
              .copyWith(color: lw.contentSecondary),
        ),
      ],
    );
  }
}

class _StreakCircle extends StatelessWidget {
  final int value;
  const _StreakCircle({required this.value});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          '$value',
          key: ValueKey(value),
          style: LWTypography.title3.copyWith(
            color: lw.brandPrimary.withValues(alpha: 0.3),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AdjustButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(LWRadius.sm),
          border: Border.all(color: lw.borderSubtle.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: lw.contentPrimary),
      ),
    );
  }
}

// ── Stake section ─────────────────────────────────────────────────────────────

class _StakeSection extends StatefulWidget {
  final BetReady state;
  const _StakeSection({required this.state});

  @override
  State<_StakeSection> createState() => _StakeSectionState();
}

class _StakeSectionState extends State<_StakeSection> {
  late StakeCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.state.isSelfBet ? StakeCategory.gift : StakeCategory.plan;
  }

  @override
  void didUpdateWidget(_StakeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isSelfBet != widget.state.isSelfBet) {
      _selectedCategory =
          widget.state.isSelfBet ? StakeCategory.gift : StakeCategory.plan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final filteredStakes = widget.state.stakes
        .where((s) => s.category == _selectedCategory)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
          child: Text(
            'Reward',
            style: LWTypography.title3.copyWith(
              color: lw.contentPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: LWSpacing.md),

        // Category tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
          child: Row(
            children: [
              _CategoryTab(
                iconName: 'tag_stake_plan',
                isActive: _selectedCategory == StakeCategory.plan,
                onTap: () =>
                    setState(() => _selectedCategory = StakeCategory.plan),
              ),
              const SizedBox(width: LWSpacing.sm),
              _CategoryTab(
                iconName: 'tag_stake_gift',
                isActive: _selectedCategory == StakeCategory.gift,
                onTap: () =>
                    setState(() => _selectedCategory = StakeCategory.gift),
              ),
              const SizedBox(width: LWSpacing.sm),
              // Plus chip — only for premium users
              Builder(builder: (ctx) {
                final authState = ctx.read<AuthBloc>().state;
                final isPremium = authState is AuthAuthenticated
                    ? authState.user.isPremium
                    : false;
                return _CategoryTab(
                  iconName: 'misc_plus',
                  isActive: false,
                  onTap: isPremium
                      ? () => CustomStakeSheet.show(context)
                      : () => ProfileDrawer.showUpgradeDialog(context),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: LWSpacing.sm),

        // Stakes list — scrollable within the remaining space
        Expanded(
          child: filteredStakes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(LWSpacing.xl),
                    child: Text(
                      'No stakes in this category yet.',
                      style: LWTypography.smallNormalRegular
                          .copyWith(color: lw.contentSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredStakes.length,
                  itemBuilder: (ctx, i) {
                    final stake = filteredStakes[i];
                    final isSelected = stake.id == widget.state.selectedStakeId;
                    return _StakeRow(
                      stake: stake,
                      isSelected: isSelected,
                      onTap: () =>
                          ctx.read<BetBloc>().add(BetStakeSelected(stake.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String iconName;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.iconName,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? lw.brandPrimary : lw.interactiveDisabled,
        ),
        alignment: Alignment.center,
        child: LwIcon(
          iconName,
          size: 24,
          color: isActive ? Colors.white : lw.contentSecondary,
        ),
      ),
    );
  }
}

class _StakeRow extends StatelessWidget {
  final StakeEntity stake;
  final bool isSelected;
  final VoidCallback onTap;

  const _StakeRow({
    required this.stake,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(
            horizontal: LWSpacing.lg, vertical: LWSpacing.xs),
        padding: const EdgeInsets.all(LWSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? lw.backgroundApp : Colors.transparent,
          borderRadius: BorderRadius.circular(LWRadius.md),
          border: Border.all(
            color: isSelected ? lw.borderSubtle : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: stake.imageAsset != null
                  ? Image.asset(
                      stake.imageAsset!,
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => Text(stake.emoji ?? '🎯',
                          style: const TextStyle(fontSize: 28)),
                    )
                  : Text(stake.emoji ?? '🎯',
                      style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: LWSpacing.lg),
            Expanded(
              child: Text(
                stake.title,
                style: LWTypography.regularNormalBold.copyWith(
                  color: isSelected ? lw.contentPrimary : lw.contentPrimary,
                  fontSize: 18,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: lw.interactiveDisabled,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: lw.contentSecondary, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Place bet button ──────────────────────────────────────────────────────────

class _PlaceBetButton extends StatelessWidget {
  final BetReady state;
  const _PlaceBetButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.submitStatus == BetSubmitStatus.submitting;

    return LwButton.primary(
      label: 'Place bet',
      onPressed: state.canPlace
          ? () => context.read<BetBloc>().add(const BetPlaceRequested())
          : null,
      isLoading: isSubmitting,
      icon: const Icon(Icons.star_rounded, size: 18),
      width: double.infinity,
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
          if (bet.imageAsset != null)
            Image.asset(
              bet.imageAsset!,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => _BettorAvatarPlaceholder(lw: lw),
            )
          else
            _BettorAvatarPlaceholder(lw: lw),
          const SizedBox(width: LWSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bet.bettorUsername ?? 'Someone',
                  style: LWTypography.regularNormalBold
                      .copyWith(color: lw.contentPrimary),
                ),
                if (bet.stakeTitle != null || bet.customStakeTitle != null)
                  Text(
                    bet.stakeTitle ?? bet.customStakeTitle!,
                    style: LWTypography.smallNormalRegular
                        .copyWith(color: lw.contentSecondary),
                  ),
              ],
            ),
          ),
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

class _BettorAvatarPlaceholder extends StatelessWidget {
  final LWThemeExtension lw;
  const _BettorAvatarPlaceholder({required this.lw});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lw.borderSubtle,
      ),
      child: Icon(Icons.person_rounded, size: 20, color: lw.contentSecondary),
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
              'No bets yet',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              'Place a bet to get started!',
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

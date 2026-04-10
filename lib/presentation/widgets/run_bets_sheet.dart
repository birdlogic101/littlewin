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
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import '../../data/repositories/bet_repository.dart';
import 'custom_stake_sheet.dart';
import 'lw_button.dart';
import 'profile_drawer.dart';
import '../../core/di/injection.dart';
import '../../domain/entities/people_user_entity.dart';
import '../pages/people/view_user_screen.dart';
import '../../data/repositories/runs_repository.dart';

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
  // Resolved from the caller's context (before modal opens) so the modal's
  // own BuildContext — which has no BlocProvider parent — doesn't need AuthBloc.
  final bool isPremium;

  const RunBetsSheet._({
    required this.runId,
    required this.currentStreak,
    required this.username,
    required this.isSelfBet,
    required this.startInPlaceMode,
    required this.betRepository,
    required this.isPremium,
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
    // Resolve isPremium here, while we still have the full BlocProvider tree.
    final authState = context.read<AuthBloc>().state;
    final isPremium =
        authState is AuthAuthenticated ? authState.user.isPremium : false;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RunBetsSheet._(
        runId: runId,
        currentStreak: currentStreak,
        username: username,
        isSelfBet: isSelfBet,
        startInPlaceMode: startInPlaceMode,
        betRepository: betRepository,
        isPremium: isPremium,
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
        isPremium: isPremium,
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
  final bool isPremium;

  const _BetExperienceContent({
    required this.username,
    required this.isSelfBet,
    required this.currentStreak,
    required this.runId,
    required this.startInPlaceMode,
    required this.isPremium,
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

        widget.onBetPlaced?.call();
        Navigator.pop(ctx);
      },
      child: Material(
        color: lw.backgroundApp,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top + 8),
          child: Column(
            children: [
              // Close button row — REMOVED to align with Figma (moved into sub-view headers)
              // Main content — switches between list and place-bet views
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
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
                          isPremium: widget.isPremium,
                          onBackTap: _toggleView,
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
        // ── Header (Matching Figma)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LWSpacing.xl, LWSpacing.lg, LWSpacing.md, LWSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Placed bets',
                style: LWTypography.title4.copyWith(
                  color: LWColors.inkDark,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 24),
                color: LWColors.inkLight,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: BlocBuilder<BetBloc, BetState>(
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

              if (state.submitStatus == BetSubmitStatus.error &&
                  state.errorMessage != null) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(LWSpacing.md),
                      child: Text(
                        state.errorMessage!,
                        style: LWTypography.smallTightRegular
                            .copyWith(color: LWColors.energyBase),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              if (state.existingBets.isEmpty) {
                return _EmptyBetsView(isSelfBet: isSelfBet);
              }
              return ListView.separated(
                // shrinkWrap: true, // Removed for better performance in expanded layout
                // physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: LWSpacing.md),
                itemCount: state.existingBets.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: LWSpacing.xl),
                itemBuilder: (_, i) => _BetRow(bet: state.existingBets[i]),
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
          child: LwButton.primary(
            label: 'Add new',
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
  final bool isPremium;
  final VoidCallback onBackTap;

  const _PlaceBetView({
    required this.username,
    required this.isSelfBet,
    required this.isPremium,
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

            // ── Header (Close button)
            Padding(
              padding: const EdgeInsets.fromLTRB(LWSpacing.md, 0, 0, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 28, color: LWColors.inkLight),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

            const Spacer(),

            // ── Streak selector (fixed at top, compact)
            _StreakSelector(state: state),

            const Spacer(),

            // ── Reward / stake section
            _StakeSection(state: state, isPremium: isPremium),

            const Spacer(),

            // ── Error message
            if (state.submitStatus == BetSubmitStatus.error &&
                state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: LWSpacing.xl, vertical: LWSpacing.xs),
                child: Text(
                  state.errorMessage!,
                  style: LWTypography.smallTightRegular
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
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Streak',
              style: LWTypography.title4.copyWith(
                color: LWColors.inkDark,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: LWSpacing.xs),
            Icon(Icons.info_outline_rounded,
                size: 20, color: LWColors.skyDark),
          ],
        ),
        const SizedBox(height: LWSpacing.lg),
        
        // 5-way selector row
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: lw.borderSubtle, width: 0.8),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          '$value',
          key: ValueKey(value),
          style: LWTypography.title4.copyWith(
            color: LWColors.primaryDark,
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
  final bool isPremium;
  const _StakeSection({required this.state, required this.isPremium});

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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Reward',
              style: LWTypography.title4.copyWith(
                color: LWColors.inkDark,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: LWSpacing.xs),
            Icon(Icons.info_outline_rounded,
                size: 20, color: LWColors.skyDark),
          ],
        ),
        const SizedBox(height: LWSpacing.lg),

        // Category tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CategoryTab(
              iconName: 'tag_stake_plan',
              isActive: _selectedCategory == StakeCategory.plan,
              onTap: () =>
                  setState(() => _selectedCategory = StakeCategory.plan),
            ),
            const SizedBox(width: LWSpacing.md),
            _CategoryTab(
              iconName: 'tag_stake_gift',
              isActive: _selectedCategory == StakeCategory.gift,
              onTap: () =>
                  setState(() => _selectedCategory = StakeCategory.gift),
            ),
            const SizedBox(width: LWSpacing.md),
            // Plus chip — for premium users only
            _CategoryTab(
              iconName: 'misc_plus',
              isActive: false,
              onTap: widget.isPremium
                  ? () => CustomStakeSheet.show(context)
                  : () => ProfileDrawer.showUpgradeDialog(context),
            ),
          ],
        ),
        const SizedBox(height: LWSpacing.sm),

        // Stakes list — shrink-wrapped for vertical centering
        filteredStakes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(LWSpacing.xl),
                  child: Text(
                    'No stakes in this category yet.',
                    style: LWTypography.smallTightRegular
                        .copyWith(color: lw.contentSecondary),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
        width: 40,
        height: 40,
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
        height: 56,
        margin: const EdgeInsets.symmetric(
            horizontal: LWSpacing.xl, vertical: 2),
        padding: const EdgeInsets.symmetric(
            horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? lw.brandSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(LWRadius.md),
        ),
        child: Row(
          children: [
            // Left: Icon frame
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: stake.imageAsset != null
                    ? Image.asset(
                        stake.imageAsset!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(stake.emoji ?? '🎯',
                            style: const TextStyle(fontSize: 24)),
                      )
                    : Text(stake.emoji ?? '🎯',
                        style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            
            // Center: Title
            Expanded(
              child: Text(
                stake.title,
                style: LWTypography.regularNoneRegular.copyWith(
                  color: isSelected ? lw.brandPrimary : LWColors.inkBase,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Right: Checkmark circle
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: lw.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              )
            else
              const SizedBox(width: 24),
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

    final statusBg = switch (bet.status) {
      BetStatus.won => LWColors.positiveBase,
      BetStatus.lost => LWColors.negativeBase,
      BetStatus.pending => LWColors.skyBase,
    };

    final statusText = switch (bet.status) {
      BetStatus.won => Colors.white,
      BetStatus.lost => Colors.white,
      BetStatus.pending => LWColors.inkLight,
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
          // 1. Streak Ring (New: added to match Figma)
          PngStreakRing(
            streak: bet.targetStreak,
            size: 40,
            numberColor: LWColors.inkDark,
          ),
          const SizedBox(width: LWSpacing.md),

          // 2. Avatar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ViewUserScreen(
                    user: PeopleUserEntity(
                      userId: bet.bettorId,
                      username: bet.bettorUsername ?? 'Anonymous',
                      avatarId: null, // Custom avatars later
                      isFollowing: false,
                      ongoingRunCount: 0,
                    ),
                    runsRepository: getIt<RunsRepository>(),
                  ),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 18,
              // TODO(profile-picture): Support custom avatars here once implemented.
              backgroundImage: AssetImage('assets/avatars/avatar_blank.jpg'),
            ),
          ),
          const SizedBox(width: LWSpacing.md),

          // 3. Info (Reward Title)
          Expanded(
            child: Text(
              bet.stakeTitle ?? bet.customStakeTitle ?? 'No reward',
              style: LWTypography.regularNoneRegular
                  .copyWith(color: LWColors.inkDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 4. Action (Three-dots menu)
          IconButton(
            onPressed: () {}, // TODO(bet-actions)
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            color: LWColors.inkLight.withValues(alpha: 0.6),
            visualDensity: VisualDensity.compact,
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

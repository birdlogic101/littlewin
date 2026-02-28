import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'profile_drawer.dart';

/// The "Place Bet" bottom sheet — streak selector + stake picker.
///
/// Always opened from [RunBetsSheet] via [PlaceBetModal.show].
/// Creates its own [BetBloc] instance scoped to this sheet's lifetime.
class PlaceBetModal extends StatelessWidget {
  final String runId;
  final int currentStreak;
  final String username;
  final bool isSelfBet;
  final BetRepository betRepository;

  const PlaceBetModal._({
    required this.runId,
    required this.currentStreak,
    required this.username,
    required this.isSelfBet,
    required this.betRepository,
  });

  /// Opens the place-bet sheet. Call this instead of navigating directly.
  static Future<bool> show(
    BuildContext context, {
    required String runId,
    required int currentStreak,
    required String username,
    required bool isSelfBet,
    required BetRepository betRepository,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceBetModal._(
        runId: runId,
        currentStreak: currentStreak,
        username: username,
        isSelfBet: isSelfBet,
        betRepository: betRepository,
      ),
    );
    return result ?? false;
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
      child: _PlaceBetSheet(
        username: username,
        isSelfBet: isSelfBet,
      ),
    );
  }
}

// ── Inner sheet widget ────────────────────────────────────────────────────────

class _PlaceBetSheet extends StatelessWidget {
  final String username;
  final bool isSelfBet;

  const _PlaceBetSheet({
    required this.username,
    required this.isSelfBet,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return BlocListener<BetBloc, BetState>(
      listenWhen: (_, curr) =>
          curr is BetReady && curr.submitStatus == BetSubmitStatus.success,
      listener: (ctx, _) {
        Navigator.of(ctx).pop(true); // signal success to RunBetsSheet
        ScaffoldMessenger.of(ctx)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Row(children: [
              const Text('⭐ ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  isSelfBet ? 'Self-bet placed! 🎉' : 'Bet placed! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ]),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LWRadius.sm)),
          ));
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: lw.backgroundApp,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LWRadius.lg)),
        ),
        child: BlocBuilder<BetBloc, BetState>(
          builder: (context, state) {
            if (state is BetLoading) {
              return Padding(
                padding: const EdgeInsets.all(LWSpacing.xxl),
                child: Center(
                  child: CircularProgressIndicator(
                      color: lw.brandPrimary, strokeWidth: 2.5),
                ),
              );
            }
            if (state is! BetReady) return const SizedBox.shrink();
            return _ReadyContent(state: state, username: username);
          },
        ),
      ),
    );
  }
}

// ── Ready content ─────────────────────────────────────────────────────────────

class _ReadyContent extends StatelessWidget {
  final BetReady state;
  final String username;

  const _ReadyContent({required this.state, required this.username});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Drag handle
        Padding(
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

        // ── Close + section header row
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LWSpacing.lg, LWSpacing.md, LWSpacing.lg, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Icon(Icons.close_rounded,
                    color: lw.contentSecondary, size: 22),
              ),
              const Spacer(),
              Text(
                state.isSelfBet ? 'Self-bet' : 'Bet on @$username',
                style:
                    LWTypography.regularNormalBold.copyWith(color: lw.contentPrimary),
              ),
              const Spacer(),
              const SizedBox(width: 22), // balance the close icon
            ],
          ),
        ),

        const SizedBox(height: LWSpacing.xl),

        // ── Streak selector
        _StreakSelector(state: state),

        const SizedBox(height: LWSpacing.xl),

        // ── Reward / stake section
        _StakeSection(state: state),

        // ── Error message
        if (state.submitStatus == BetSubmitStatus.error &&
            state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
            child: Text(
              state.errorMessage!,
              style: LWTypography.smallNormalRegular
                  .copyWith(color: LWColors.energyBase),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: LWSpacing.lg),

        // ── Place bet button
        Padding(
          padding: EdgeInsets.fromLTRB(
            LWSpacing.xl,
            0,
            LWSpacing.xl,
            MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
          ),
          child: _PlaceBetButton(state: state),
        ),
      ],
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
            Text(
              'Streak',
              style:
                  LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(width: LWSpacing.xs),
            Tooltip(
              message:
                  'Bet that this run will reach ${state.targetStreak} consecutive days',
              child: Icon(Icons.info_outline_rounded,
                  size: 16, color: lw.contentSecondary),
            ),
          ],
        ),
        const SizedBox(height: LWSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              icon: Icons.keyboard_double_arrow_left_rounded,
              onTap: () => context
                  .read<BetBloc>()
                  .add(const BetTargetChanged(-10)),
            ),
            const SizedBox(width: LWSpacing.sm),
            _AdjustButton(
              icon: Icons.chevron_left_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(-1)),
            ),
            const SizedBox(width: LWSpacing.lg),
            _StreakCircle(value: state.targetStreak),
            const SizedBox(width: LWSpacing.lg),
            _AdjustButton(
              icon: Icons.chevron_right_rounded,
              onTap: () =>
                  context.read<BetBloc>().add(const BetTargetChanged(1)),
            ),
            const SizedBox(width: LWSpacing.sm),
            _AdjustButton(
              icon: Icons.keyboard_double_arrow_right_rounded,
              onTap: () => context
                  .read<BetBloc>()
                  .add(const BetTargetChanged(10)),
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
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          '$value',
          key: ValueKey(value),
          style: LWTypography.title3.copyWith(color: LWColors.skyBase),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: lw.backgroundCard,
          borderRadius: BorderRadius.circular(LWRadius.sm),
          border: Border.all(color: lw.borderSubtle),
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
  StakeCategory _selectedCategory = StakeCategory.plan;

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
            style:
                LWTypography.title4.copyWith(color: lw.contentPrimary),
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

        // Stakes list — constrained height so sheet doesn't overflow
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
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
                  shrinkWrap: true,
                  itemCount: filteredStakes.length,
                  itemBuilder: (ctx, i) {
                    final stake = filteredStakes[i];
                    final isSelected =
                        stake.id == widget.state.selectedStakeId;
                    return _StakeRow(
                      stake: stake,
                      isSelected: isSelected,
                      onTap: () => ctx
                          .read<BetBloc>()
                          .add(BetStakeSelected(stake.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  /// SVG icon name from assets/icons (without extension).
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? LWColors.skyBase : const Color(0xFFEEEEEE),
        ),
        alignment: Alignment.center,
        child: LwIcon(
          iconName,
          size: 22,
          color: isActive ? Colors.white : Colors.grey.shade600,
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
        margin:
            const EdgeInsets.symmetric(horizontal: LWSpacing.lg, vertical: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: LWSpacing.lg, vertical: LWSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? LWColors.skyBase.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(LWRadius.md),
        ),
        child: Row(
          children: [
            // PNG image with emoji fallback
            SizedBox(
              width: 36,
              height: 36,
              child: stake.imageAsset != null
                  ? Image.asset(
                      stake.imageAsset!,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) =>
                          Text(stake.emoji ?? '🎯',
                              style: const TextStyle(fontSize: 22)),
                    )
                  : Text(stake.emoji ?? '🎯',
                      style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: LWSpacing.md),
            Expanded(
              child: Text(
                stake.title,
                style: LWTypography.regularNormalRegular.copyWith(
                  color: isSelected ? LWColors.skyBase : lw.contentPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: LWColors.skyBase,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14),
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

    return SizedBox(
      width: double.infinity,
      height: LWComponents.button.height,
      child: ElevatedButton(
        onPressed: state.canPlace
            ? () => context.read<BetBloc>().add(const BetPlaceRequested())
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: LWColors.skyBase,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LWColors.skyBase.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: LWElevation.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LWRadius.pill),
          ),
          textStyle: LWComponents.button.labelStyle,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Place bet'),
                ],
              ),
      ),
    );
  }
}

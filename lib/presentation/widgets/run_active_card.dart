import 'package:flutter/material.dart';
import '../../domain/entities/active_run_entity.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import '../../core/theme/design_system.dart';

/// A list-item card representing one of the user's active runs.
class RunActiveCard extends StatelessWidget {
  final ActiveRunEntity run;
  final bool forceDone;
  final VoidCallback? onCheckin;
  final VoidCallback? onBetTap;

  const RunActiveCard({
    super.key,
    required this.run,
    this.forceDone = false,
    this.onCheckin,
    this.onBetTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.xs,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.lg),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          // 1. Streak Ring
          PngStreakRing(
            streak: run.currentStreak,
            size: 50,
            numberColor: LWColors.inkBase,
          ),
          const SizedBox(width: LWSpacing.md),

          // 2. Title + Bet Configuration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  run.challengeTitle,
                  style: LWTypography.regularNoneRegular.copyWith(
                    color: LWColors.inkBase,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onBetTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LWColors.skyLightest,
                      borderRadius: BorderRadius.circular(LWRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: run.betCount == 0
                              ? lw.brandPrimary
                              : lw.contentSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          run.betCount == 0 ? 'Bet' : '${run.betCount}',
                          style: LWTypography.smallNoneBold.copyWith(
                            color: run.betCount == 0
                                ? lw.brandPrimary
                                : lw.contentSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. More Actions Button (Three-dots)
          IconButton(
            onPressed: () {}, // TODO(more-actions)
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: lw.contentSecondary.withValues(alpha: 0.6),
            ),
            splashRadius: 20,
          ),

          // 4. Checkin Status
          _CheckinToggle(
            isChecked: run.hasCheckedInToday || forceDone,
            onChanged: onCheckin == null ? null : (v) => onCheckin!(),
          ),
        ],
      ),
    );
  }
}

class _CheckinToggle extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?>? onChanged;

  const _CheckinToggle({
    required this.isChecked,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!isChecked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChecked ? lw.brandPrimary : LWColors.inkLighter,
            width: 1.5,
          ),
          color: isChecked ? lw.brandPrimary : LWColors.skyLightest,
        ),
        child: isChecked
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

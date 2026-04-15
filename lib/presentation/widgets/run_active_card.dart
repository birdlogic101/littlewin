import 'package:flutter/material.dart';
import '../../domain/entities/active_run_entity.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import 'lw_card_action.dart';
import 'lw_pill_action.dart';
import 'challenge_description_sheet.dart';
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
        horizontal: 8,
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
            size: 64,
            numberColor: LWColors.inkBase,
          ),
          const SizedBox(width: LWSpacing.md),

          // 2. Title + Bet Configuration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start, // Higher positioning
              children: [
                const SizedBox(height: 4), // Optical nudge for "Higher" title
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => ChallengeDescriptionSheet.show(
                          context,
                          title: run.challengeTitle,
                          description: run.challengeDescription,
                          challengeId: run.challengeId,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          run.challengeTitle,
                          style: LWTypography.regularNoneBold.copyWith(
                            color: LWColors.inkBase,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!run.isPublic)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: const LwIcon(
                          'misc_incognito',
                          size: 16,
                          color: LWColors.skyDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12), // Increased gap to 12
                LWPillAction(
                  icon: Icons.star_rounded,
                  label: run.betCount == 0 ? 'Bet' : '${run.betCount}',
                  onTap: onBetTap,
                  contentColor: run.betCount == 0
                      ? lw.brandPrimary
                      : lw.contentSecondary,
                ),
              ],
            ),
          ),

          // 3. Checkin Status
          LWCardAction(
            icon: Icons.check_rounded,
            isChecked: run.hasCheckedInToday || forceDone,
            isCheckbox: true,
            onTap: onCheckin,
            semanticLabel: 'Check in',
          ),
        ],
      ),
    );
  }
}

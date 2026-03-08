import 'package:flutter/material.dart';
import '../../domain/entities/active_run_entity.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import '../../core/theme/design_system.dart';

/// A list-item card representing one of the user's active runs.
///
/// Displays the challenge background (gradient fallback when no image),
/// challenge title, star bet button (with count), streak ring, and a
/// one-tap check-in button.
/// When [run.hasCheckedInToday] is true the check-in button shows a done state.
class RunActiveCard extends StatelessWidget {
  final ActiveRunEntity run;

  /// When true, overrides [run.hasCheckedInToday] and shows the green done
  /// state. Used by [CheckinScreen] during the exit-animation window so the
  /// card turns green before disappearing.
  final bool forceDone;

  /// Called when the check-in button is tapped. Pass null to disable.
  final VoidCallback? onCheckin;

  /// Called when the user taps the star / bet count row.
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
      padding: const EdgeInsets.all(LWSpacing.md),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          // 1. Streak Ring
          PngStreakRing(
            streak: run.currentStreak,
            size: LWComponents.streakRing.diameterMd,
            numberColor: lw.contentPrimary,
          ),
          const SizedBox(width: LWSpacing.md),

          // 2. Title + Bet Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        run.challengeTitle,
                        style: LWTypography.regularNormalBold.copyWith(
                          color: lw.contentPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: lw.contentSecondary.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 22, // Stable height for meta info row
                  child: GestureDetector(
                    onTap: onBetTap,
                    behavior: HitTestBehavior.opaque,
                    child: run.betCount == 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: LWSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(LWRadius.pill),
                              border: Border.all(
                                color: lw.brandPrimary.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: lw.brandPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bet',
                                  style: LWTypography.smallNormalBold.copyWith(
                                    color: lw.brandPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LWSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: lw.backgroundSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: lw.contentSecondary.withOpacity(0.4),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${run.betCount} bet${run.betCount == 1 ? '' : 's'}',
                                      style: LWTypography.smallNormalRegular.copyWith(
                                        color: lw.contentSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // 3. More Menu
          _CircleIconBtn(
            semanticLabel: 'More actions',
            icon: Icons.more_vert_rounded,
            onTap: () {
              // TODO: implement more actions menu
            },
            color: lw.contentSecondary,
          ),
          const SizedBox(width: LWSpacing.md),

          // 4. Check-in Button
          _CheckinButton(
            done: forceDone || run.hasCheckedInToday,
            onTap: (forceDone || run.hasCheckedInToday) ? null : onCheckin,
          ),
        ],
      ),
    );
  }
}

class _CheckinButton extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;

  const _CheckinButton({required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Semantics(
      label: done ? 'Already checked in' : 'Check in',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 36, // Slightly smaller per design
          height: 36,
          decoration: BoxDecoration(
            color: done ? LWColors.positiveBase : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: done ? LWColors.positiveBase : lw.borderStrong,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color color;
  final IconData icon;

  const _CircleIconBtn({
    required this.semanticLabel,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 24,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: color.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/challenge_record.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import 'lw_card_action.dart';
import 'lw_pill_action.dart';
import '../../core/theme/design_system.dart';

/// A card representing a challenge group in the Records screen.
class RunRecordCard extends StatelessWidget {
  final ChallengeRecord record;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final VoidCallback? onViewHistory;
  final String? actionLabel;
  final String? actionIcon;
  final double? iconSize;

  const RunRecordCard({
    super.key,
    required this.record,
    this.onShare,
    this.onRetry,
    this.onViewHistory,
    this.actionLabel,
    this.actionIcon,
    this.iconSize,
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
          PngStreakRing(
            streak: record.bestScore,
            size: 64,
            numberColor: LWColors.inkBase,
          ),
          const SizedBox(width: LWSpacing.md),

          // ── Title + run count ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onViewHistory,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, // Higher positioning
                children: [
                  const SizedBox(height: 4), // Optical nudge
                  Row(
                    children: [
                      if (!record.isPublic)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: LwIcon(
                            'misc_incognito',
                            size: 16,
                            color: lw.contentSecondary.withOpacity(0.7),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          record.challengeTitle,
                          style: LWTypography.regularNoneBold.copyWith(
                            color: LWColors.inkBase,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Increased gap to 12
                  LWPillAction(
                    icon: 'misc_list_dropdown',
                    label: '${record.runCount}',
                    onTap: onViewHistory,
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actionLabel != null)
                LWCardAction(
                  icon: actionIcon ?? 'misc_plus',
                  iconSize: iconSize ?? 24,
                  onTap: onRetry,
                  semanticLabel: actionLabel,
                )
              else
                LWCardAction(
                  icon: 'misc_restart',
                  onTap: onRetry,
                  semanticLabel: 'Retry challenge',
                ),
            ],
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../domain/entities/challenge_record.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';
import '../../core/theme/design_system.dart';

/// A card representing a challenge group in the Records screen.
///
/// Matches the preview design:
/// - Circular score ring (best run) on the left
/// - Challenge title + "N runs" count
/// - Share arrow + retry icons on the right
class RunRecordCard extends StatelessWidget {
  final ChallengeRecord record;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final VoidCallback? onViewHistory;

  const RunRecordCard({
    super.key,
    required this.record,
    this.onShare,
    this.onRetry,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.xs,
      ),
      padding: const EdgeInsets.all(12), // Aligned with RunActiveCard
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.lg), // Matching RunActiveCard
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          PngStreakRing(
            streak: record.bestScore,
            size: 50, // Standardized size
            numberColor: lw.contentPrimary,
          ),
          const SizedBox(width: LWSpacing.md),

          // ── Title + run count ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onViewHistory,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.challengeTitle,
                    style: LWTypography.regularNoneRegular.copyWith(
                      color: LWColors.inkBase,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onViewHistory,
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
                          LwIcon(
                            'misc_list_dropdown',
                            size: 14,
                            color: lw.contentSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record.runCount}',
                            style: LWTypography.smallNoneBold.copyWith(
                              color: lw.contentSecondary,
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
          ),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {}, // TODO: implement more actions menu
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: lw.contentSecondary.withValues(alpha: 0.6),
                ),
                splashRadius: 20,
              ),
              const SizedBox(width: LWSpacing.xs),
              _RetryButton(onTap: onRetry),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _RetryButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Semantics(
      label: 'Retry challenge',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24, // Aligned with Check-in toggle weight
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: lw.borderStrong,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.refresh_rounded,
            size: 16, // Proportional to 24x24 container
            color: lw.contentSecondary.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String semanticLabel;
  final IconData iconData;
  final VoidCallback? onTap;
  final Color color;

  const _IconBtn({
    required this.semanticLabel,
    required this.color,
    required this.iconData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            iconData,
            size: 20,
            color: color.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

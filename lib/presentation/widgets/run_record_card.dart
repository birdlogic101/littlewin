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
  final String? actionLabel;
  final String? actionIcon;

  const RunRecordCard({
    super.key,
    required this.record,
    this.onShare,
    this.onRetry,
    this.onViewHistory,
    this.actionLabel,
    this.actionIcon,
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
            size: 68, // Updated to High-Fidelity size
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
              if (actionLabel == null)
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
              if (actionLabel != null)
                actionLabel == 'Join'
                    ? _JoinButton(onTap: onRetry ?? () {})
                    : _PillAction(
                        icon: actionIcon ?? 'misc_plus',
                        label: actionLabel!,
                        onTap: onRetry ?? () {},
                      )
              else
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
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: LWColors.skyLightest, // SkyLighter
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.refresh_rounded,
            size: 24,
            color: LWColors.inkLight, // InkLight
          ),
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LWColors.skyLightest,
          borderRadius: BorderRadius.circular(LWRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LwIcon(icon, size: 14, color: LWColors.primaryBase),
            const SizedBox(width: 4),
            Text(
              label,
              style: LWTypography.smallNoneBold.copyWith(
                color: LWColors.primaryBase,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _JoinButton extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: LWColors.skyLighter,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: LwIcon(
          'misc_join',
          size: 14,
          color: LWColors.inkLight,
        ),
      ),
    );
  }
}

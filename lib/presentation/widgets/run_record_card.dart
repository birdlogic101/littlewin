import 'package:flutter/material.dart';
import '../../domain/entities/challenge_record.dart';
import 'png_streak_ring.dart';
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

  const RunRecordCard({
    super.key,
    required this.record,
    this.onShare,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.md,
      ),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          // ── Score ring ───────────────────────────────────────────────────
          PngStreakRing(
            streak: record.bestScore,
            size: 64,
          ),
          const SizedBox(width: LWSpacing.lg),

          // ── Title + run count ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.challengeTitle,
                  style: LWTypography.regularNormalBold
                      .copyWith(color: lw.contentPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 14,
                      color: lw.contentSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.runCount} ${record.runCount == 1 ? 'run' : 'runs'}',
                      style: LWTypography.smallNormalRegular
                          .copyWith(color: lw.contentSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBtn(
                semanticLabel: 'Share',
                icon: Icons.send_rounded,
                onTap: onShare,
                color: lw.contentSecondary,
              ),
              const SizedBox(width: LWSpacing.sm),
              _IconBtn(
                semanticLabel: 'Retry challenge',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
                color: lw.contentSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _IconBtn({
    required this.semanticLabel,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: LWThemeExtension.of(context).backgroundApp,
            shape: BoxShape.circle,
            border: Border.all(
              color: LWThemeExtension.of(context).borderSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

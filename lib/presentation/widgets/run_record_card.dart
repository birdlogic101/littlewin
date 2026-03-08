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
      padding: const EdgeInsets.all(LWSpacing.md),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          PngStreakRing(
            streak: record.bestScore,
            size: LWComponents.streakRing.diameterMd,
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
                    style: LWTypography.regularNormalBold
                        .copyWith(color: lw.contentPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_rounded,
                          size: 16,
                          color: lw.contentSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${record.runCount} ${record.runCount == 1 ? 'run' : 'runs'}',
                          style: LWTypography.smallNormalRegular
                              .copyWith(color: lw.contentSecondary),
                        ),
                      ],
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
              _IconBtn(
                semanticLabel: 'More actions',
                iconData: Icons.more_vert_rounded,
                onTap: () {
                  // TODO: implement more actions menu
                },
                color: lw.contentSecondary,
              ),
              const SizedBox(width: LWSpacing.md),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: lw.borderStrong,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
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

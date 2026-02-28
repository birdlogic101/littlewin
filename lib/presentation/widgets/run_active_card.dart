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

  /// Number of bets currently placed on this run. Shown below the title.
  final int betCount;

  /// Called when the user taps the star / bet count row.
  final VoidCallback? onBetTap;

  const RunActiveCard({
    super.key,
    required this.run,
    this.forceDone = false,
    this.onCheckin,
    this.betCount = 0,
    this.onBetTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.sm,
      ),
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LWRadius.md),
        color: lw.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
          _RunCardBackground(
            imageAsset: run.imageAsset,
            imageUrl: run.imageUrl,
            title: run.challengeTitle,
          ),

          // ── Dark gradient for readability ────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Content row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LWSpacing.lg,
              vertical: LWSpacing.md,
            ),
            child: Row(
              children: [
                // Left: title + streak count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        run.challengeTitle,
                        style: LWTypography.regularNormalBold.copyWith(
                          color: Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Star bet row
                      GestureDetector(
                        onTap: onBetTap,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            LwIcon(
                              'misc_bet',
                              size: 13,
                              color: betCount > 0
                                  ? const Color(0xFFFFAB40)
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              betCount > 0
                                  ? '$betCount bet${betCount == 1 ? '' : 's'}'
                                  : 'No bets yet',
                              style: LWTypography.smallNormalRegular.copyWith(
                                color: betCount > 0
                                    ? Colors.white70
                                    : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: LWSpacing.md),

                // Right: Streak ring + check-in button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PngStreakRing(
                      streak: run.currentStreak,
                      size: LWComponents.streakRing.diameterMd,
                    ),
                  ],
                ),

                const SizedBox(width: LWSpacing.md),

                // Check-in button
                _CheckinButton(
                  done: forceDone || run.hasCheckedInToday,
                  onTap: (forceDone || run.hasCheckedInToday) ? null : onCheckin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ──────────────────────────────────────────────────────────────

class _RunCardBackground extends StatelessWidget {
  final String? imageAsset;
  final String? imageUrl;
  final String title;

  const _RunCardBackground({
    required this.imageAsset,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _GradientFallback(title: title),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _GradientFallback(title: title),
      );
    }
    return _GradientFallback(title: title);
  }
}

class _GradientFallback extends StatelessWidget {
  final String title;
  const _GradientFallback({required this.title});

  Color _color() {
    const palette = [
      Color(0xFF2D6A4F),
      Color(0xFF1B4332),
      Color(0xFF264653),
      Color(0xFF6D4C41),
      Color(0xFF37474F),
      Color(0xFF4A148C),
      Color(0xFF1A237E),
      Color(0xFF880E4F),
    ];
    return palette[title.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final base = _color();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.4)!],
        ),
      ),
    );
  }
}

// ── Check-in Button ──────────────────────────────────────────────────────────

class _CheckinButton extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;

  const _CheckinButton({required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: done ? 'Already checked in' : 'Check in',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: done
                ? LWColors.positiveBase.withValues(alpha: 0.90)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(LWRadius.sm),
            border: done
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.70),
                    width: 2,
                  ),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    color: Colors.white,
                    size: 22,
                  )
                : const SizedBox.shrink(key: ValueKey('todo')),
          ),
        ),
      ),
    );
  }
}

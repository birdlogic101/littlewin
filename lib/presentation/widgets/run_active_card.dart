import 'package:flutter/material.dart';
import '../../domain/entities/active_run_entity.dart';
import 'streak_ring.dart';
import '../../core/theme/design_system.dart';

/// A list-item card representing one of the user's active runs.
///
/// Displays the challenge background (gradient fallback when no image),
/// challenge title, current streak ring, and a one-tap check-in button.
/// When [run.hasCheckedInToday] is true the button shows a success state.
class RunActiveCard extends StatelessWidget {
  final ActiveRunEntity run;

  /// When true, overrides [run.hasCheckedInToday] and shows the green done
  /// state. Used by [CheckinScreen] during the exit-animation window so the
  /// card turns green before disappearing.
  final bool forceDone;

  /// Called when the check-in button is tapped. Pass null to disable.
  final VoidCallback? onCheckin;

  const RunActiveCard({
    super.key,
    required this.run,
    this.forceDone = false,
    this.onCheckin,
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
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: LWColors.energyBase,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${run.currentStreak} day streak',
                            style: LWTypography.smallNormalRegular.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: LWSpacing.md),

                // Right: Streak ring + check-in button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreakRing(
                      streak: run.currentStreak,
                      diameter: LWComponents.streakRing.diameterMd,
                      trackWidth: LWComponents.streakRing.trackWidth,
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: done
                ? LWColors.positiveBase.withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (done ? LWColors.positiveBase : Colors.white)
                    .withValues(alpha: 0.30),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    color: Colors.white,
                    size: 26,
                  )
                : Icon(
                    Icons.add_rounded,
                    key: const ValueKey('todo'),
                    color: LWColors.inkDarkest,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}

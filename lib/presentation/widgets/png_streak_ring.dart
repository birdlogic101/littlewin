import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

/// Streak display using the gold arc PNG asset + a centered number.
///
/// Replaces the old [StreakRing] CustomPainter everywhere in the app.
///
/// The PNG asset (`streak_ring_218x128.png`) is a transparent golden arc.
/// The number is drawn over it; use [numberColor] to contrast with the
/// background (e.g. white for photo cards, contentPrimary for white cards).
class PngStreakRing extends StatelessWidget {
  final int streak;

  /// Overall bounding box size (the PNG scales to fill it).
  final double size;

  /// Text colour of the streak number. Defaults to [LWThemeExtension.contentPrimary].
  final Color? numberColor;

  /// Font size of the streak number. Defaults to `size * 0.36`.
  final double? fontSize;

  /// Optional text shown below the number (e.g. "DAY STREAK").
  final String? subLabel;

  /// Optional text shadows for the streak number (e.g. on photo backgrounds).
  final List<Shadow>? numberShadows;

  const PngStreakRing({
    super.key,
    required this.streak,
    this.size = 84,
    this.numberColor,
    this.fontSize,
    this.subLabel,
    this.numberShadows,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final effectiveFontSize = fontSize ?? (size * 0.32).clamp(12.0, 52.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/misc/streak_ring_218x128.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
              Transform.translate(
                offset: const Offset(0, -1), // Optical nudge for centering
                child: Text(
                  '$streak',
                  style: LWTypography.largeNoneBold.copyWith(
                    fontSize: effectiveFontSize,
                    color: numberColor ?? LWColors.inkBase,
                    shadows: numberShadows ?? const [],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: LWSpacing.xs),
          Text(
            subLabel!.toUpperCase(),
            style: LWTypography.tinyNoneBold.copyWith(
              color: (numberColor ?? lw.contentPrimary).withValues(alpha: 0.85),
              fontSize: (size * 0.11).clamp(9.0, 12.0),
              letterSpacing: 1.0,
              shadows: numberShadows,
            ),
          ),
        ],
      ],
    );
  }
}

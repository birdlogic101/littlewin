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

  const PngStreakRing({
    super.key,
    required this.streak,
    this.size = 84,
    this.numberColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final effectiveFontSize = fontSize ?? (size * 0.36).clamp(12.0, 52.0);

    return SizedBox(
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
          Text(
            '$streak',
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w800,
              color: numberColor ?? lw.contentPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

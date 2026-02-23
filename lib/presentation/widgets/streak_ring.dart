import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

/// A circular progress arc showing the current streak count.
///
/// Matches the Figma design: gold arc over a subtle grey track,
/// bold number in the centre, "DAY STREAK" label below.
class StreakRing extends StatelessWidget {
  /// The current streak value displayed in the centre.
  final int streak;

  /// 0.0–1.0 fill fraction. If null, the arc fills to streak/90.
  final double? progress;

  final double diameter;
  final double trackWidth;

  const StreakRing({
    super.key,
    required this.streak,
    this.progress,
    this.diameter = 90,
    this.trackWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final fill = (progress ?? (streak / 90).clamp(0.0, 1.0));

    return SizedBox(
      width: diameter,
      height: diameter + 20, // room for label below
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: diameter,
            height: diameter,
            child: CustomPaint(
              painter: _RingPainter(
                progress: fill,
                trackColor: lw.streakRingTrack,
                fillColor: lw.streakRingFill,
                trackWidth: trackWidth,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak',
                      style: LWTypography.title4.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DAY STREAK',
            style: LWTypography.tinyNoneBold.copyWith(
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double trackWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.trackWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - trackWidth / 2;
    const startAngle = -math.pi / 2; // top

    // Track (full circle)
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.35)
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..strokeWidth = trackWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/design_system.dart';

/// Reusable SVG icon from assets/icons/.
class LwIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final List<Shadow>? shadows;

  const LwIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? LWThemeExtension.of(context).contentPrimary;
    final svg = SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );

    if (shadows == null || shadows!.isEmpty) return svg;

    return Stack(
      children: [
        for (final shadow in shadows!)
          Positioned(
            left: shadow.offset.dx,
            top: shadow.offset.dy,
            child: Opacity(
              opacity: shadow.color.opacity,
              child: SvgPicture.asset(
                'assets/icons/$name.svg',
                width: size,
                height: size,
                colorFilter: ColorFilter.mode(
                  shadow.color.withOpacity(1.0),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        svg,
      ],
    );
  }
}

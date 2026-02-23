import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/design_system.dart';

/// Reusable SVG icon from assets/icons/.
class LwIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const LwIcon(this.name, {super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? LWThemeExtension.of(context).contentPrimary;
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

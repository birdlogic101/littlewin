import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import 'lw_icon.dart';

/// A unified pill-shaped action/label used for card metadata (e.g. Bets, Runs).
class LWPillAction extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback? onTap;
  
  /// Color of the text and icon.
  final Color? contentColor;
  
  /// Background color of the pill.
  final Color? backgroundColor;

  const LWPillAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.contentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    
    // Fallback to theme colors if not provided
    final Color effectiveContentColor = contentColor ?? lw.contentSecondary;
    final Color effectiveBgColor = backgroundColor ?? LWColors.skyLightest;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(LWRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(effectiveContentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: LWTypography.smallNoneBold.copyWith(
                color: effectiveContentColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    if (icon is IconData) {
      return Icon(icon as IconData, size: 14, color: color);
    } else if (icon is String) {
      return LwIcon(icon as String, size: 14, color: color);
    }
    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import 'lw_icon.dart';

/// A unified action button used in cards across the app.
/// 
/// Replaces local implementations for:
/// - Check-in toggle
/// - Retry button
/// - Join button
class LWCardAction extends StatelessWidget {
  /// The icon to display. Supports both Material Icons and custom [LwIcon] slugs.
  final dynamic icon;
  
  /// Whether the action is in a "checked" or "active" state (e.g. for Check-in).
  final bool isChecked;
  
  /// Callback when the button is tapped. Null disables interaction.
  final VoidCallback? onTap;
  
  /// Optional label for accessibility.
  final String? semanticLabel;

  /// Optional icon size (defaults to 24).
  final double iconSize;

  /// Whether this action is a checkbox (check-in style) or a standard icon action.
  final bool isCheckbox;

  const LWCardAction({
    super.key,
    required this.icon,
    this.isChecked = false,
    this.isCheckbox = false,
    this.onTap,
    this.semanticLabel,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    
    // ── Style Logic ────────────────────────────────────────────────────────
    
    final Color bgColor = isCheckbox && isChecked 
        ? LWColors.skyLightest 
        : LWColors.skyLightest;
        
    final Color? borderColor = isCheckbox && !isChecked 
        ? lw.brandPrimary 
        : null;
        
    final Color contentColor = isCheckbox 
        ? (isChecked ? LWColors.positiveBase : Colors.transparent)
        : lw.brandPrimary;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LWRadius.xs),
            color: bgColor,
            border: borderColor != null 
                ? Border.all(color: borderColor, width: 1.5) 
                : null,
          ),
          alignment: Alignment.center,
          child: _buildIcon(contentColor),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    // If checked, slightly smaller icon (if iconSize is 24, it becomes 20)
    final double iconS = isChecked ? (iconSize * 0.83).roundToDouble() : iconSize;

    if (icon is IconData) {
      return Icon(
        icon as IconData,
        size: iconS,
        color: color,
      );
    } else if (icon is String) {
      return LwIcon(
        icon as String,
        size: iconS,
        color: color,
      );
    }
    return const SizedBox.shrink();
  }
}

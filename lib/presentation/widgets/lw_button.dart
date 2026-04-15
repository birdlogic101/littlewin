import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

/// A centralized button widget that implements the Littlewin button hierarchy.
///
/// Variants:
/// - [LWButtonVariant.primary]: High-prominence CTA.
/// - [LWButtonVariant.secondary]: Medium-prominence action.
/// - [LWButtonVariant.ghost]: Low-prominence action.
/// - [LWButtonVariant.action]: Inverse/Action button for dark contexts.
///
/// Sizes:
/// - [LWButtonSize.large]: 56dp height.
/// - [LWButtonSize.medium]: 48dp height.
/// - [LWButtonSize.small]: 36dp height.
class LwButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LWButtonVariant variant;
  final LWButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const LwButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LWButtonVariant.primary,
    this.size = LWButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.width,
    this.foregroundColor,
    this.backgroundColor,
  });

  /// Shorthand for a primary button.
  factory LwButton.primary({
    required String label,
    VoidCallback? onPressed,
    LWButtonSize size = LWButtonSize.medium,
    bool isLoading = false,
    Widget? icon,
    double? width,
    Color? foregroundColor,
    Color? backgroundColor,
  }) =>
      LwButton(
        label: label,
        onPressed: onPressed,
        variant: LWButtonVariant.primary,
        size: size,
        isLoading: isLoading,
        icon: icon,
        width: width,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );

  /// Shorthand for a secondary button.
  factory LwButton.secondary({
    required String label,
    VoidCallback? onPressed,
    LWButtonSize size = LWButtonSize.medium,
    bool isLoading = false,
    Widget? icon,
    double? width,
    Color? foregroundColor,
    Color? backgroundColor,
  }) =>
      LwButton(
        label: label,
        onPressed: onPressed,
        variant: LWButtonVariant.secondary,
        size: size,
        isLoading: isLoading,
        icon: icon,
        width: width,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );

  /// Shorthand for a ghost button.
  factory LwButton.ghost({
    required String label,
    VoidCallback? onPressed,
    LWButtonSize size = LWButtonSize.medium,
    bool isLoading = false,
    Widget? icon,
    double? width,
    Color? foregroundColor,
    Color? backgroundColor,
  }) =>
      LwButton(
        label: label,
        onPressed: onPressed,
        variant: LWButtonVariant.ghost,
        size: size,
        isLoading: isLoading,
        icon: icon,
        width: width,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      );

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final themeButton = LWComponents.button;

    final backgroundColor = _getBackgroundColor(lw);
    final effectiveForegroundColor = foregroundColor ?? _getForegroundColor(lw);
    final side = _getBorderSide(lw);

    return SizedBox(
      width: width,
      height: themeButton.height(size),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: effectiveForegroundColor,
          disabledBackgroundColor: backgroundColor?.withOpacity(0.6),
          disabledForegroundColor: effectiveForegroundColor?.withOpacity(0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: themeButton.padding(size),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeButton.radius),
            side: side ?? BorderSide.none,
          ),
          textStyle: themeButton.labelStyle(size),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return effectiveForegroundColor?.withOpacity(0.1);
            }
            return null;
          }),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveForegroundColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  Color? _getBackgroundColor(LWThemeExtension lw) {
    if (backgroundColor != null) return backgroundColor;
    return switch (variant) {
      LWButtonVariant.primary => lw.brandPrimary,
      LWButtonVariant.secondary => lw.brandSubtle,
      LWButtonVariant.ghost => Colors.transparent,
      LWButtonVariant.action => Colors.white,
    };
  }

  Color? _getForegroundColor(LWThemeExtension lw) {
    return switch (variant) {
      LWButtonVariant.primary => lw.onBrandPrimary,
      LWButtonVariant.secondary => lw.brandPrimary,
      LWButtonVariant.ghost => lw.brandPrimary,
      LWButtonVariant.action => LWColors.inkDarkest,
    };
  }

  BorderSide? _getBorderSide(LWThemeExtension lw) {
    if (variant == LWButtonVariant.secondary) {
      // Optional: if we want outline for secondary in some themes
      // return BorderSide(color: lw.brandPrimary, width: 1);
    }
    return null;
  }
}

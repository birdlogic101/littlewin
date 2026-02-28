import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import 'lw_icon.dart';

/// A compact, centered app-bar-style header used on the Check-in, Records,
/// and People screens.
///
/// Mirrors the visual language from the sketch previews:
/// - Centered title in [LWTypography.regularNormalRegular] (light weight, not bold)
/// - Optional trailing icon button (defaults to the cog / misc_cog)
///
/// Does **not** extend [PreferredSizeWidget] — rendered as a plain widget
/// inside each screen's own column so those screens can stay Scaffold-free
/// (they live inside HomePage's IndexedStack).
class LwPageHeader extends StatelessWidget {
  final String title;

  /// SVG icon name (assets/icons/[name].svg) for the trailing action.
  final String trailingIcon;
  final VoidCallback? onTrailingTap;
  final String trailingSemanticLabel;

  const LwPageHeader({
    super.key,
    required this.title,
    this.trailingIcon = 'misc_cog',
    this.onTrailingTap,
    this.trailingSemanticLabel = 'Settings',
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered title
            Text(
              title,
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentPrimary),
              textAlign: TextAlign.center,
            ),
            // Trailing icon — right-aligned
            Positioned(
              right: 4,
              child: Semantics(
                label: trailingSemanticLabel,
                button: true,
                child: InkWell(
                  onTap: onTrailingTap,
                  borderRadius: BorderRadius.circular(LWRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.all(LWSpacing.md),
                    child: LwIcon(
                      trailingIcon,
                      size: 22,
                      color: lw.contentPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

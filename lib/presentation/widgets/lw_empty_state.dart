import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/design_system.dart';
import 'lw_button.dart';
import 'lw_icon.dart';

/// Configuration for an action button in the empty state.
class LWEmptyStateAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isPremium; // If true, shows the crown icon

  const LWEmptyStateAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isPremium = false,
  });
}

/// A premium, standardized empty state view used across the app.
class LWEmptyState extends StatelessWidget {
  final String? symbolPath;
  final String title;
  final String subtitle;
  final List<LWEmptyStateAction> actions;

  const LWEmptyState({
    super.key,
    this.symbolPath,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xxl, vertical: LWSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Symbol
            SvgPicture.asset(
              symbolPath ?? 'assets/misc/misc_logo512.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(lw.borderStrong, BlendMode.srcIn),
            ),
            const SizedBox(height: LWSpacing.xxl),

            // ── Title
            Text(
              title,
              style: LWTypography.largeNormalBold.copyWith(
                fontSize: 20,
                color: LWColors.inkBase,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // ── Subtitle
            Text(
              subtitle,
              style: LWTypography.smallNormalRegular.copyWith(color: LWColors.inkLighter),
              textAlign: TextAlign.center,
            ),

            // ── Actions
            if (actions.isNotEmpty) ...[
              const SizedBox(height: LWSpacing.xxxl),
              ...actions.map((action) {
                final isLast = action == actions.last;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : LWSpacing.md),
                  child: action.isPrimary
                      ? LwButton.primary(
                          label: action.label,
                          onPressed: action.onPressed,
                          width: double.infinity,
                        )
                      : LwButton.secondary(
                          label: action.label,
                          onPressed: action.onPressed,
                          width: double.infinity,
                        ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

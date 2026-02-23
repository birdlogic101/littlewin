import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import 'lw_icon.dart';

/// The shared app bar used across all top-level screens.
///
/// Left:   hamburger menu (settings drawer)
/// Center: ✌️ logo + "littlewin" wordmark
/// Right:  + create (premium users only) · 🔔 notifications
class LwAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onCreateTap;
  final VoidCallback? onNotificationsTap;

  /// When true the + button is shown (premium user or admin).
  final bool showCreate;

  /// Badge count for notification bell. 0 = no badge.
  final int notificationCount;

  const LwAppBar({
    super.key,
    this.onMenuTap,
    this.onCreateTap,
    this.onNotificationsTap,
    this.showCreate = false,
    this.notificationCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return AppBar(
      backgroundColor: lw.backgroundApp,
      elevation: LWElevation.none,
      centerTitle: true,
      leadingWidth: 56,
      leading: _SvgBtn(
        iconName: 'misc_menu_lines',
        onTap: onMenuTap,
        semanticLabel: 'Menu',
      ),
      title: _Wordmark(),
      actions: [
        if (showCreate)
          _SvgBtn(
            iconName: 'misc_plus',
            onTap: onCreateTap,
            semanticLabel: 'Create challenge',
          ),
        _NotificationBtn(
          count: notificationCount,
          onTap: onNotificationsTap,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _SvgBtn extends StatelessWidget {
  final String iconName;
  final VoidCallback? onTap;
  final String semanticLabel;

  const _SvgBtn({
    required this.iconName,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LWRadius.pill),
        child: Padding(
          padding: const EdgeInsets.all(LWSpacing.md),
          child: LwIcon(iconName, size: 22, color: lw.contentPrimary),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('✌️', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: LWSpacing.xs),
        Text(
          'littlewin',
          style: LWTypography.largeNoneBold.copyWith(color: lw.contentPrimary),
        ),
      ],
    );
  }
}

class _NotificationBtn extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _NotificationBtn({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Semantics(
      label: 'Notifications${count > 0 ? ", $count unread" : ""}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LWRadius.pill),
        child: Padding(
          padding: const EdgeInsets.all(LWSpacing.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LwIcon('misc_bell', size: 22, color: lw.contentPrimary),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: LWComponents.badge.sizeSmall,
                    height: LWComponents.badge.sizeSmall,
                    decoration: BoxDecoration(
                      color: lw.feedbackNegative,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: LWComponents.badge.labelStyle.copyWith(
                        color: lw.contentInverse,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

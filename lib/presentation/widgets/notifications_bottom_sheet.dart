import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications/notifications_bloc.dart';
import '../bloc/notifications/notifications_event.dart';
import '../bloc/notifications/notifications_state.dart';
import 'lw_icon.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationsBloc>(),
        child: const NotificationsBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: lw.backgroundApp,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(LWRadius.lg),
      ),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // ── Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: LWSpacing.md),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: LWColors.skyBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(context, lw),
            // Divider removed for consistency with CreateChallengeSheet
            Expanded(
              child: BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotificationsError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is NotificationsLoaded) {
                    if (state.notifications.isEmpty) {
                      return _buildEmptyState(lw);
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        LWSpacing.lg,
                        0,
                        LWSpacing.lg,
                        bottomPadding + LWSpacing.lg,
                      ),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.sm),
                      itemBuilder: (context, index) {
                        return _NotificationTile(notification: state.notifications[index]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LWThemeExtension lw) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LWSpacing.xl, LWSpacing.lg, LWSpacing.sm, LWSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notifications',
              style: LWTypography.largeNoneBold.copyWith(
                color: LWColors.inkBase,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationsBloc>().add(
                  const NotificationsMarkAllAsReadRequested());
            },
            child: Text(
              'Mark all read',
              style: LWTypography.smallNoneMedium.copyWith(
                color: lw.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LWThemeExtension lw) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LwIcon('misc_bell', size: 48, color: lw.contentSecondary.withOpacity(0.3)),
          const SizedBox(height: LWSpacing.md),
          Text(
            'No notifications yet',
            style: LWTypography.regularNormalMedium.copyWith(color: lw.contentSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final isUnread = notification.status == NotificationStatus.pending;

    return InkWell(
      onTap: () {
        context.read<NotificationsBloc>().add(NotificationMarkAsReadRequested(notification.id));
        if (notification.deepLink != null) {
          context.pop();
          context.push(notification.deepLink!);
        }
      },
      borderRadius: BorderRadius.circular(LWRadius.md),
      child: Container(
        padding: const EdgeInsets.all(LWSpacing.md),
        decoration: BoxDecoration(
          color: isUnread ? lw.brandPrimary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(LWRadius.md),
          border: Border.all(
            color: isUnread ? lw.brandPrimary.withOpacity(0.1) : lw.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(lw),
            const SizedBox(width: LWSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: LWTypography.regularNormalMedium.copyWith(
                      color: lw.contentPrimary,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: LWTypography.tinyNormalRegular.copyWith(color: lw.contentSecondary),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: lw.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(LWThemeExtension lw) {
    final iconName = switch (notification.type) {
      NotificationType.betWon => 'nav_scores',
      NotificationType.betLost => 'nav_scores',
      NotificationType.betReceived => 'nav_home',
      NotificationType.newFollower => 'nav_people',
      NotificationType.checkinReminder => 'nav_checkin',
    };

    return Container(
      padding: const EdgeInsets.all(LWSpacing.sm),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        shape: BoxShape.circle,
      ),
      child: LwIcon(iconName, size: 20, color: lw.contentPrimary),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

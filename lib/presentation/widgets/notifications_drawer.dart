import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications/notifications_bloc.dart';
import '../bloc/notifications/notifications_event.dart';
import '../bloc/notifications/notifications_state.dart';
import 'lw_icon.dart';
import 'user_card.dart';
import '../../data/repositories/runs_repository.dart';
import '../../core/di/injection.dart';
import 'run_bets_sheet.dart';
import '../bloc/checkin/checkin_bloc.dart';
import '../bloc/checkin/checkin_event.dart';

class NotificationsDrawer extends StatelessWidget {
  final ValueChanged<int>? onTabSwitch;
  const NotificationsDrawer({super.key, this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Drawer(
      width: 320,
      backgroundColor: lw.backgroundApp,
      child: Column(
        children: [
          SizedBox(height: topPadding),
          _buildHeader(context, lw),
          const Divider(height: 1, thickness: 1),
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
                      LWSpacing.md,
                      LWSpacing.lg,
                      bottomPadding + LWSpacing.lg,
                    ),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.sm),
                    itemBuilder: (context, index) {
                      return _NotificationTile(
                        notification: state.notifications[index],
                        onTabSwitch: onTabSwitch,
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LWThemeExtension lw) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LWSpacing.lg, vertical: LWSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: LWTypography.title4.copyWith(
              color: LWColors.inkBase,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const LwIcon('misc_cross', size: 24, color: LWColors.skyDark),
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
  final ValueChanged<int>? onTabSwitch;

  const _NotificationTile({required this.notification, this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final isUnread = notification.status == NotificationStatus.pending;

    return InkWell(
      onTap: () => _handleTileTap(context),
      borderRadius: BorderRadius.circular(LWRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: LWSpacing.md, horizontal: LWSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              avatarId: notification.sourceAvatarId,
              size: 40,
            ),
            const SizedBox(width: LWSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageRichText(context),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: LWTypography.tinyNormalRegular.copyWith(
                      color: lw.contentSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: LWSpacing.sm),
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: lw.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRichText(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final baseStyle = LWTypography.smallNormalRegular.copyWith(
      color: LWColors.skyDark,
    );
    final boldStyle = LWTypography.smallNormalBold.copyWith(
      color: LWColors.inkBase,
    );

    final meta = notification.metadata ?? {};
    final username = meta['username'] as String? ?? 'Someone';
    final target = meta['target_streak']?.toString() ?? 'Goal';
    final rawRunTitle = meta['run_title'] as String? ?? 'Challenge';
    final finalStreak = meta['final_streak']?.toString() ?? '0';

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: switch (notification.type) {
          NotificationType.newFollower => [
              TextSpan(text: username, style: boldStyle),
              const TextSpan(text: ' is now following you.'),
            ],
          NotificationType.betReceived => [
              TextSpan(text: username, style: boldStyle),
              const TextSpan(text: ' has placed a bet on '),
              TextSpan(text: 'Day $target', style: boldStyle),
              const TextSpan(text: ' of your '),
              TextSpan(text: rawRunTitle, style: boldStyle),
              const TextSpan(text: ' run.'),
            ],
          NotificationType.betWon => [
              const TextSpan(text: 'Congratulations! You won '),
              TextSpan(text: meta['stake_title'] ?? 'your bet', style: boldStyle),
              const TextSpan(text: ' by reaching '),
              TextSpan(text: 'Day $target', style: boldStyle),
              const TextSpan(text: ' in your '),
              TextSpan(text: rawRunTitle, style: boldStyle),
              const TextSpan(text: ' run.'),
            ],
          NotificationType.betLost => [
              const TextSpan(text: 'Your '),
              TextSpan(text: rawRunTitle, style: boldStyle),
              const TextSpan(text: ' run ended at '),
              TextSpan(text: 'Day $finalStreak.', style: boldStyle),
            ],
          _ => [
              const TextSpan(text: 'It\'s time for your '),
              TextSpan(text: rawRunTitle, style: boldStyle),
              const TextSpan(text: ' check-in.'),
            ],
        },
      ),
    );
  }

  void _handleTileTap(BuildContext context) {
    if (notification.status == NotificationStatus.pending) {
      // First tap: Mark as read
      context.read<NotificationsBloc>().add(NotificationMarkAsReadRequested(notification.id));
    } else {
      // Second tap: Execute navigation/action
      _executeNotificationAction(context);
    }
  }

  void _executeNotificationAction(BuildContext context) {
    final type = notification.type;
    final meta = notification.metadata ?? {};

    Navigator.pop(context); // Close drawer

    switch (type) {
      case NotificationType.betReceived:
      case NotificationType.betWon:
        final runId = meta['run_id'] as String?;
        if (runId != null) {
          onTabSwitch?.call(1); // Check-in tab
          context.read<CheckinBloc>().add(CheckinRunBetsOpened(runId: runId));
        }
        break;
      case NotificationType.newFollower:
        // Handle nav to profile...
        break;
      case NotificationType.checkinReminder:
        onTabSwitch?.call(1);
        break;
      case NotificationType.betLost:
        onTabSwitch?.call(2);
        break;
      default:
        // Navigate based on deepLink if available
        if (notification.deepLink != null) {
          context.push(notification.deepLink!);
        }
        break;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

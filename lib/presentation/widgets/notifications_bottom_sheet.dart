import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/di/injection.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/bet_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/runs_repository.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications/notifications_bloc.dart';
import '../bloc/notifications/notifications_event.dart';
import '../bloc/notifications/notifications_state.dart';
import '../pages/people/view_user_screen.dart';
import 'lw_button.dart';
import 'lw_icon.dart';
import 'run_bets_sheet.dart';
import 'user_card.dart';

class NotificationsBottomSheet extends StatelessWidget {
  final ValueChanged<int> onTabSwitch;

  const NotificationsBottomSheet({
    super.key,
    required this.onTabSwitch,
  });

  static Future<void> show(BuildContext context, {required ValueChanged<int> onTabSwitch}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationsBloc>(),
        child: NotificationsBottomSheet(onTabSwitch: onTabSwitch),
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
  final ValueChanged<int> onTabSwitch;

  const _NotificationTile({
    required this.notification,
    required this.onTabSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final isUnread = notification.status == NotificationStatus.pending;

    return InkWell(
      onTap: () => _handleTileTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: LWSpacing.md, horizontal: LWSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _handleAvatarTap(context),
              child: UserAvatar(
                avatarId: notification.sourceAvatarId,
                size: 40,
              ),
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
                  if (notification.type == NotificationType.betLost &&
                      notification.metadata?['challenge_id'] != null) ...[
                    const SizedBox(height: LWSpacing.sm),
                    LwButton.primary(
                      label: 'Retry',
                      size: LWButtonSize.small,
                      width: 100,
                      onPressed: () => _handleRetry(context),
                    ),
                  ],
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
      color: lw.contentSecondary.withOpacity(0.8),
    );
    final boldStyle = LWTypography.smallNormalBold.copyWith(
      color: lw.contentPrimary,
    );

    final meta = notification.metadata ?? {};
    final username = meta['username'] as String? ?? 'Someone';
    final target = meta['target_streak']?.toString() ?? 'Goal';
    final rawRunTitle = meta['run_title'] as String? ?? 'Challenge';
    final finalStreak = meta['final_streak']?.toString() ?? '0';

    // Helper to avoid "Yoga Run run"
    final runTitle = rawRunTitle.toLowerCase().contains('run') 
        ? rawRunTitle 
        : '$rawRunTitle run';

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
              const TextSpan(text: ' placed a bet on your '),
              TextSpan(text: runTitle, style: boldStyle),
              const TextSpan(text: '.'),
            ],
          NotificationType.betWon => [
              const TextSpan(text: 'You won! You reached '),
              TextSpan(text: 'Day $target', style: boldStyle),
              const TextSpan(text: ' of your '),
              TextSpan(text: runTitle, style: boldStyle),
              const TextSpan(text: '.'),
            ],
          NotificationType.betLost => [
              const TextSpan(text: 'Your '),
              TextSpan(text: runTitle, style: boldStyle),
              const TextSpan(text: ' ended at '),
              TextSpan(text: 'Day $finalStreak.', style: boldStyle),
            ],
          _ => [
              const TextSpan(text: 'It\'s time for your '),
              TextSpan(text: runTitle, style: boldStyle),
              const TextSpan(text: ' check-in.'),
            ],
        },
      ),
    );
  }

  Future<void> _handleRetry(BuildContext context) async {
    final challengeId = notification.metadata?['challenge_id'] as String?;
    final runTitle = notification.metadata?['run_title'] as String?;
    if (challengeId == null) return;

    try {
      await getIt<RunsRepository>().joinChallenge(
        challengeId,
        title: runTitle ?? 'Joining...',
      );
      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        // The AppShell handles switching to Check-in tab when lastJoinedAt changes
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to retry: $e')),
        );
      }
    }
  }

  Future<void> _handleAvatarTap(BuildContext context) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final targetId = notification.sourceUserId;
    if (targetId == null || targetId == uid) return;

    // Show a loading indicator if fetching takes a second
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading user profile...'), duration: Duration(milliseconds: 500)),
    );

    try {
      final user = await getIt<PeopleRepository>().fetchUser(targetId);
      if (user != null && context.mounted) {
        Navigator.pop(context); // Close drawer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewUserScreen(
              user: user,
              runsRepository: getIt<RunsRepository>(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  void _handleTileTap(BuildContext context) {
    context.read<NotificationsBloc>().add(NotificationMarkAsReadRequested(notification.id));

    final type = notification.type;
    final meta = notification.metadata ?? {};

    Navigator.pop(context); // Close drawer first

    switch (type) {
      case NotificationType.betReceived:
        final runId = meta['run_id'] as String?;
        if (runId != null) {
          RunBetsSheet.show(
            context,
            runId: runId,
            currentStreak: meta['current_streak'] as int? ?? 0,
            username: meta['username'] as String? ?? 'User',
            isSelfBet: meta['is_self_bet'] as bool? ?? false,
            betRepository: getIt<BetRepository>(),
          );
        }
        break;
      case NotificationType.betWon:
      case NotificationType.checkinReminder:
        onTabSwitch(1); // Check-in tab
        break;
      case NotificationType.betLost:
        onTabSwitch(2); // Records tab
        break;
      case NotificationType.newFollower:
        _handleAvatarTap(context);
        break;
      default:
        onTabSwitch(0); // Home tab
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

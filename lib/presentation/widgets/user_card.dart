import 'package:flutter/material.dart';
import '../../domain/entities/people_user_entity.dart';
import '../../core/theme/design_system.dart';

enum UserCardMode {
  /// Used in the Followed / Followers tab lists.
  /// Shows: avatar | username + "🔥 N ongoing" | chevron
  listRow,

  /// Used in the AddPerson search sheet.
  /// Shows: avatar | username | Follow / Unfollow button
  searchResult,
}

/// A user row card used in the People tab.
class UserCard extends StatelessWidget {
  final PeopleUserEntity user;
  final UserCardMode mode;

  /// Called when the Follow/Unfollow button is tapped (searchResult mode)
  /// or when the row itself is tapped (listRow mode — no-op for now).
  final VoidCallback? onFollowToggle;

  const UserCard({
    super.key,
    required this.user,
    required this.mode,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.md,
      ),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          // ── Avatar ───────────────────────────────────────────────────
          _UserAvatar(avatarId: user.avatarId),
          const SizedBox(width: LWSpacing.md),

          // ── Username + optional sub-label ────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: LWTypography.regularNormalBold
                      .copyWith(color: lw.contentPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mode == UserCardMode.listRow && user.ongoingRunCount > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${user.ongoingRunCount} ongoing',
                        style: LWTypography.smallNormalRegular
                            .copyWith(color: lw.contentSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: LWSpacing.md),

          // ── Trailing action ───────────────────────────────────────────
          if (mode == UserCardMode.searchResult)
            _FollowButton(isFollowing: user.isFollowing, onTap: onFollowToggle)
          else
            Icon(Icons.chevron_right_rounded,
                color: lw.contentSecondary, size: 20),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final int? avatarId;
  const _UserAvatar({this.avatarId});

  @override
  Widget build(BuildContext context) {
    final size = LWComponents.avatar.md;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LWColors.skyLight,
        border: Border.all(
          color: LWThemeExtension.of(context).borderSubtle,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarId != null
          ? Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
            )
          : const _AvatarPlaceholder(),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_rounded, color: Colors.white70, size: 24);
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onTap;

  const _FollowButton({required this.isFollowing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Semantics(
      label: isFollowing ? 'Unfollow user' : 'Follow user',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: LWSpacing.lg,
            vertical: LWSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isFollowing ? lw.interactiveDefault : lw.brandPrimary,
            borderRadius: BorderRadius.circular(LWRadius.pill),
            border: isFollowing
                ? Border.all(color: lw.borderStrong, width: 1)
                : null,
          ),
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: LWTypography.smallNoneMedium.copyWith(
              color: isFollowing ? lw.contentPrimary : lw.onBrandPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/people_user_entity.dart';
import '../../core/theme/design_system.dart';

/// A user row card used in the People tab.
///
/// Displays avatar, username, and a Follow / Unfollow toggle button.
class UserCard extends StatelessWidget {
  final PeopleUserEntity user;
  final VoidCallback onFollowToggle;

  const UserCard({
    super.key,
    required this.user,
    required this.onFollowToggle,
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
          // ── Avatar ────────────────────────────────────────────────────
          _UserAvatar(avatarId: user.avatarId),

          const SizedBox(width: LWSpacing.md),

          // ── Username ──────────────────────────────────────────────────
          Expanded(
            child: Text(
              user.username,
              style: LWTypography.regularNormalBold
                  .copyWith(color: lw.contentPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: LWSpacing.md),

          // ── Follow / Unfollow button ───────────────────────────────────
          _FollowButton(
            isFollowing: user.isFollowing,
            onTap: onFollowToggle,
          ),
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
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

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

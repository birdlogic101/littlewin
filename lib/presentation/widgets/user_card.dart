import 'package:flutter/material.dart';
import '../../domain/entities/people_user_entity.dart';
import '../../core/theme/design_system.dart';
import 'lw_icon.dart';

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
  final VoidCallback? onFollowToggle;

  /// Called when the row itself is tapped (listRow mode).
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.mode,
    this.onFollowToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return GestureDetector(
      onTap: mode == UserCardMode.listRow ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64, // Increased height for breathing room
        padding: const EdgeInsets.symmetric(horizontal: LWSpacing.lg),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────────────────────────
            UserAvatar(avatarId: user.avatarId),
            const SizedBox(width: LWSpacing.md),
    
            // ── Username + sub-label ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          style: LWTypography.smallNoneBold
                              .copyWith(color: LWColors.inkBase),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isPremium) ...[
                        const SizedBox(width: 4),
                        const LwIcon(
                          'misc_crown',
                          size: 14,
                          color: Color(0xFFFFD700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10), // Increased spacing for better breathing
                  // Ongoing runs pill: always visible, 20px height
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: LWColors.skyLightest,
                      borderRadius: BorderRadius.circular(LWRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LwIcon('misc_streak', size: 16, color: LWColors.skyDark),
                        const SizedBox(width: 4),
                        Text(
                          '${user.ongoingRunCount}',
                          style: LWTypography.smallNoneBold.copyWith(
                            color: LWColors.skyDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    
            const SizedBox(width: LWSpacing.md),
    
            // ── Trailing action ───────────────────────────────────────────
            if (mode == UserCardMode.searchResult)
              _FollowButton(isFollowing: user.isFollowing, onTap: onFollowToggle)
            else
              const LwIcon(
                'arrows_next',
                size: 24,
                color: LWColors.skyDark,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final int? avatarId;
  final double size;
  const UserAvatar({this.avatarId, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: LWColors.skyLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarId != null
          ? Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const AvatarPlaceholder(),
            )
          : const AvatarPlaceholder(),
    );
  }
}

class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder();

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
        onTap: isFollowing ? null : onTap, // Per UX request: "not the place to unfollow"
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : lw.brandPrimary,
            shape: BoxShape.circle,
            border: isFollowing
                ? Border.all(color: lw.borderSubtle, width: 1.5)
                : null,
          ),
          child: Icon(
            isFollowing ? Icons.check_rounded : Icons.add_rounded,
            size: 20,
            color: isFollowing ? lw.contentSecondary : lw.onBrandPrimary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/explore_run_entity.dart';
import '../widgets/streak_ring.dart';
import '../widgets/lw_icon.dart';
import '../../core/theme/design_system.dart';

/// Full-bleed, full-screen swipeable card showing a single public run.
///
/// Supports horizontal swipe gestures:
/// - Swipe **right** (> 80 px) → joins the challenge (calls [onJoin]).
/// - Swipe **left**  (< -80 px) → dismisses the card (calls [onDismiss]).
///
/// A subtle horizontal translation follows the finger for tactile feedback.
/// The card snaps back to center if the swipe doesn't cross the threshold.
class ExploreRunCard extends StatefulWidget {
  final ExploreRunEntity run;
  final VoidCallback onDismiss;
  final VoidCallback onJoin;

  const ExploreRunCard({
    super.key,
    required this.run,
    required this.onDismiss,
    required this.onJoin,
  });

  @override
  State<ExploreRunCard> createState() => _ExploreRunCardState();
}

class _ExploreRunCardState extends State<ExploreRunCard>
    with SingleTickerProviderStateMixin {
  static const double _threshold = 80.0;

  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;
  double _dragX = 0;

  /// Overlay state: null=none, 'join'=green flash, 'dismiss'=red flash.
  String? _overlay;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    setState(() => _dragX += d.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_dragX > _threshold) {
      _triggerJoin();
    } else if (_dragX < -_threshold) {
      _triggerDismiss();
    } else {
      _snapBack();
    }
  }

  void _triggerJoin() {
    setState(() => _overlay = 'join');
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) widget.onJoin();
    });
  }

  void _triggerDismiss() {
    setState(() => _overlay = 'dismiss');
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _snapBack() {
    final begin = _dragX;
    _snapAnimation = Tween<double>(begin: begin, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    );
    _snapController.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragX = 0);
    });
    _snapAnimation.addListener(() {
      if (mounted) setState(() => _dragX = _snapAnimation.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX * 0.35, 0), // follow finger at 35% speed
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Card content ──────────────────────────────────────────────
            Stack(
              fit: StackFit.expand,
              children: [
                _CardBackground(
                  imageAsset: widget.run.imageAsset,
                  imageUrl: widget.run.imageUrl,
                  title: widget.run.challengeTitle,
                ),
                _BottomGradient(),
                Positioned(
                  top: 24,
                  left: LWSpacing.lg,
                  right: LWSpacing.lg,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserBadge(
                          username: widget.run.username,
                          avatarId: widget.run.avatarId),
                      const Spacer(),
                      StreakRing(
                        streak: widget.run.currentStreak,
                        diameter: 84,
                        trackWidth: 6,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomContent(
                    title: widget.run.challengeTitle,
                    onDismiss: widget.onDismiss,
                    onJoin: widget.onJoin,
                  ),
                ),
              ],
            ),

            // ── Swipe feedback overlay ─────────────────────────────────────
            if (_overlay == 'join')
              _SwipeFlash(color: const Color(0xFF2D9B5A), label: 'Joined! 🎉'),
            if (_overlay == 'dismiss')
              _SwipeFlash(color: const Color(0xFF444444), label: 'Skipped'),

            // ── Live drag hint arrows ──────────────────────────────────────
            if (_dragX.abs() > 20)
              _DragHint(dragX: _dragX, threshold: _threshold),
          ],
        ),
      ),
    );
  }
}

// ── Swipe flash ───────────────────────────────────────────────────────────────

class _SwipeFlash extends StatelessWidget {
  final Color color;
  final String label;
  const _SwipeFlash({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Text(
        label,
        style: LWTypography.title3.copyWith(
          color: Colors.white,
          shadows: const [Shadow(blurRadius: 12, color: Colors.black54)],
        ),
      ),
    );
  }
}

// ── Drag hint icon ────────────────────────────────────────────────────────────

class _DragHint extends StatelessWidget {
  final double dragX;
  final double threshold;
  const _DragHint({required this.dragX, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final isRight = dragX > 0;
    final progress = (dragX.abs() / threshold).clamp(0.0, 1.0);
    return Positioned(
      top: 0,
      bottom: 0,
      left: isRight ? LWSpacing.xxl : null,
      right: isRight ? null : LWSpacing.xxl,
      child: Opacity(
        opacity: progress,
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isRight
                  ? const Color(0xFF2D9B5A).withValues(alpha: 0.85)
                  : Colors.black54,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isRight ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CardBackground extends StatelessWidget {
  final String? imageAsset;
  final String? imageUrl;
  final String title;
  const _CardBackground({
    required this.imageAsset,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackBackground(title: title),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackBackground(title: title),
      );
    }
    return _FallbackBackground(title: title);
  }
}

class _FallbackBackground extends StatelessWidget {
  final String title;
  const _FallbackBackground({required this.title});

  Color _color() {
    const palette = [
      Color(0xFF2D6A4F),
      Color(0xFF1B4332),
      Color(0xFF264653),
      Color(0xFF6D4C41),
      Color(0xFF37474F),
      Color(0xFF4A148C),
      Color(0xFF1A237E),
      Color(0xFF880E4F),
    ];
    return palette[title.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final base = _color();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.4)!],
        ),
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.45, 1.0],
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.72),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final String username;
  final int? avatarId;
  const _UserBadge({required this.username, this.avatarId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(avatarId: avatarId),
        const SizedBox(width: LWSpacing.sm),
        Text(
          username,
          style: LWTypography.regularNormalBold.copyWith(
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final int? avatarId;
  const _Avatar({this.avatarId});

  @override
  Widget build(BuildContext context) {
    final size = LWComponents.avatar.md;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LWColors.skyBase,
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarId != null
          ? Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarPlaceholder(),
            )
          : _AvatarPlaceholder(),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_rounded, color: Colors.white70, size: 24);
  }
}

class _BottomContent extends StatelessWidget {
  final String title;
  final VoidCallback onDismiss;
  final VoidCallback onJoin;
  const _BottomContent({
    required this.title,
    required this.onDismiss,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LWSpacing.xl,
        0,
        LWSpacing.xl,
        LWSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: LWTypography.title3.copyWith(
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 12, color: Colors.black87)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: LWSpacing.xl),
          Row(
            children: [
              _CircleAction(
                semanticLabel: 'Dismiss',
                onTap: onDismiss,
                child: LwIcon('misc_cross', size: 20, color: Colors.white),
              ),
              const SizedBox(width: LWSpacing.lg),
              Expanded(
                child: SizedBox(
                  height: LWComponents.button.height,
                  child: ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: LWColors.inkDarkest,
                      elevation: LWElevation.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.pill),
                      ),
                      padding: EdgeInsets.zero,
                      textStyle: LWComponents.button.labelStyle,
                    ),
                    child: const Text('Join'),
                  ),
                ),
              ),
              const SizedBox(width: LWSpacing.lg),
              _CircleAction(
                semanticLabel: 'Place a bet',
                onTap: () {},
                child: LwIcon('misc_bet', size: 20, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _CircleAction({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: LWComponents.button.height,
          height: LWComponents.button.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

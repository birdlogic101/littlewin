import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../../core/theme/design_system.dart';
import 'lw_button.dart';

/// Full-screen celebration overlay shown when a check-in triggers won bets.
///
/// Displays confetti, the challenge title, reached streak, a "DAYS COMPLETED!"
/// sub-head, and a REWARDS list with one row per won bet.
///
/// Call [BetWonModal.show] — it pushes a full-screen route and returns when
/// the user taps "Continue".
class BetWonModal extends StatefulWidget {
  final BetResolutionEntity resolution;
  final bool isBettorView;

  const BetWonModal._({
    required this.resolution,
    this.isBettorView = false,
  });

  static Future<void> show(
    BuildContext context, {
    required BetResolutionEntity resolution,
    bool isBettorView = false,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => BetWonModal._(
          resolution: resolution,
          isBettorView: isBettorView,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<BetWonModal> createState() => _BetWonModalState();
}

class _BetWonModalState extends State<BetWonModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final res = widget.resolution;

    return Scaffold(
      backgroundColor: lw.backgroundApp,
      body: Stack(
        children: [
          // ── Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_confettiController.value),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Challenge title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LWSpacing.xl),
                  child: Text(
                    res.challengeTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: LWColors.inkBase,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: LWSpacing.xxl),

                // Streak ring (PNG asset + number overlay)
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/misc/streak_ring_218x128.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        '${res.newStreak}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: LWColors.inkBase,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: LWSpacing.xl),

                // "DAYS COMPLETED!" (or [RUNNER] WON!)
                Text(
                  widget.isBettorView
                      ? (res.wonBets.isNotEmpty && res.wonBets.first.bettorUsername != null
                          ? '${res.wonBets.first.bettorUsername!.toUpperCase()} WON!'
                          : 'RUNNER WON!')
                      : 'DAYS COMPLETED !',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LWColors.skyDark,
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(flex: 2),

                // Rewards section
                if (res.wonBets.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xl),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: lw.borderSubtle)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LWSpacing.md),
                          child: Text(
                            'REWARDS',
                            style: LWTypography.tinyNormalRegular.copyWith(
                              color: LWColors.skyDark,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: lw.borderSubtle)),
                      ],
                    ),
                  ),
                  const SizedBox(height: LWSpacing.lg),
                  Flexible(
                    flex: 4,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: LWSpacing.xl),
                      itemCount: res.wonBets.length,
                      itemBuilder: (_, i) =>
                          _RewardRow(entry: res.wonBets[i]),
                    ),
                  ),
                  const SizedBox(height: LWSpacing.xl),
                ] else ...[
                  const Spacer(flex: 3),
                ],

                // Continue button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    LWSpacing.xl,
                    0,
                    LWSpacing.xl,
                    MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
                  ),
                  child: LwButton.secondary(
                    label: 'Continue',
                    onPressed: () => Navigator.of(context).pop(),
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reward row ─────────────────────────────────────────────────────────────────

class _RewardRow extends StatelessWidget {
  final WonBetEntry entry;
  const _RewardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    final displayName = entry.isSelfBet
        ? 'You'
        : (entry.bettorUsername ?? 'Someone');

    final isGift = entry.stakeCategory?.name == 'gift';
    final svgAsset = isGift ? 'assets/icons/tag_stake_gift.svg' : 'assets/icons/tag_stake_plan.svg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LWSpacing.md),
      child: Row(
        children: [
          // Bettor avatar
          _BettorAvatar(
            avatarId: entry.bettorAvatarId,
            username: displayName,
            isSelf: entry.isSelfBet,
          ),
          const SizedBox(width: LWSpacing.md), // tighter spacing like mockup

          // Stake title and username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.stakeTitle ?? 'No stake',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: LWColors.inkLighter,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: LWColors.skyBase,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ⋮ placeholder (no action for MLP)
          Icon(Icons.more_vert_rounded, size: 24, color: lw.contentPrimary.withOpacity(0.5)),
        ],
      ),
    );
  }
}

class _BettorAvatar extends StatelessWidget {
  final int? avatarId;
  final String username;
  final bool isSelf;
  const _BettorAvatar({
    required this.avatarId,
    required this.username,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    if (isSelf) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LWColors.skyBase.withOpacity(0.15),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.star_rounded,
            size: 18, color: LWColors.skyBase),
      );
    }

    if (avatarId != null) {
      return ClipOval(
        child: Image.asset(
          'assets/avatars/avatar_$avatarId.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(
              username: username, size: size),
        ),
      );
    }

    return _InitialsAvatar(username: username, size: size);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String username;
  final double size;
  const _InitialsAvatar({required this.username, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = username.isNotEmpty
        ? username[0].toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFDDDDDD),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
    );
  }
}

// ── Confetti painter ───────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter(this.progress);

  // Seeded list of confetti pieces — deterministic on each frame
  static final _rng = math.Random(42);
  static final _pieces = List.generate(60, (_) => _ConfettiPiece(_rng));

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in _pieces) {
      piece.draw(canvas, size, progress);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPiece {
  final double xFraction;   // 0..1 horizontal start
  final double delay;        // 0..1 stagger
  final double speed;        // relative fall speed
  final Color color;
  final double size;
  final int shape; // 0=rect, 1=circle, 2=triangle

  _ConfettiPiece(math.Random rng)
      : xFraction = rng.nextDouble(),
        delay = rng.nextDouble() * 0.4,
        speed = 0.6 + rng.nextDouble() * 0.4,
        color = _colors[rng.nextInt(_colors.length)],
        size = 6 + rng.nextDouble() * 8,
        shape = rng.nextInt(3);

  static const _colors = [
    Color(0xFF32B9D4), // deeper teal/cyan
    Color(0xFFFFCC33), // golden yellow
    Color(0xFFFF4558), // bright red/pink
    Color(0xFF86E0F8), // light cyan
    Color(0xFFFF909D), // light pink
  ];

  void draw(Canvas canvas, Size size_, double progress) {
    final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (t <= 0) return;

    final x = xFraction * size_.width;
    final y = -40 + t * speed * (size_.height + 80);
    final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
    final rotation = t * math.pi * 4 * speed;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    switch (shape) {
      case 0:
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: size, height: size * 0.5),
            paint);
      case 1:
        canvas.drawCircle(Offset.zero, size * 0.5, paint);
      default:
        final path = Path()
          ..moveTo(0, -size * 0.5)
          ..lineTo(size * 0.5, size * 0.5)
          ..lineTo(-size * 0.5, size * 0.5)
          ..close();
        canvas.drawPath(path, paint);
    }

    canvas.restore();
  }
}

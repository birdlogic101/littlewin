import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/bet_resolution_entity.dart';
import '../../domain/entities/stake_entity.dart';
import '../../core/theme/design_system.dart';

/// Full-screen celebration overlay shown when a check-in triggers won bets.
///
/// Displays confetti, the challenge title, reached streak, a "DAYS COMPLETED!"
/// sub-head, and a REWARDS list with one row per won bet.
///
/// Call [BetWonModal.show] — it pushes a full-screen route and returns when
/// the user taps "Continue".
class BetWonModal extends StatefulWidget {
  final BetResolutionEntity resolution;

  const BetWonModal._({required this.resolution});

  /// Pushes a full-screen overlay and awaits user dismissal.
  static Future<void> show(
    BuildContext context, {
    required BetResolutionEntity resolution,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => BetWonModal._(resolution: resolution),
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
      backgroundColor: Colors.white,
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
                const SizedBox(height: 80),

                // Challenge title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LWSpacing.xl),
                  child: Text(
                    res.challengeTitle,
                    style: LWTypography.title2.copyWith(
                      color: lw.contentPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: LWSpacing.xxl),

                // Streak ring (PNG asset + number overlay)
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/misc/streak_ring_218x128.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        '${res.newStreak}',
                        style: LWTypography.title1.copyWith(
                          color: lw.contentPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: LWSpacing.xl),

                // "DAYS COMPLETED!"
                Text(
                  'DAYS COMPLETED !',
                  style: LWTypography.title4.copyWith(
                    color: lw.contentPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: LWSpacing.xxl),

                // Rewards section
                if (res.wonBets.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: LWSpacing.md),
                        child: Text(
                          'REWARDS',
                          style: LWTypography.smallNormalRegular.copyWith(
                            color: lw.contentSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: LWSpacing.sm),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: LWSpacing.lg),
                      itemCount: res.wonBets.length,
                      itemBuilder: (_, i) =>
                          _RewardRow(entry: res.wonBets[i]),
                    ),
                  ),
                ],

                const Spacer(),

                // Continue button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    LWSpacing.xl,
                    0,
                    LWSpacing.xl,
                    MediaQuery.paddingOf(context).bottom + LWSpacing.lg,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: LWComponents.button.height,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: LWColors.skyBase.withValues(alpha: 0.5),
                            width: 1.5),
                        foregroundColor: LWColors.skyBase,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LWRadius.pill),
                        ),
                        textStyle: LWComponents.button.labelStyle,
                        backgroundColor:
                            LWColors.skyBase.withValues(alpha: 0.08),
                      ),
                      child: const Text('Continue'),
                    ),
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

    final stakeIcon = switch (entry.stakeCategory) {
      StakeCategory.gift => Icons.card_giftcard_rounded,
      _ => Icons.calendar_month_rounded,
    };

    final displayName = entry.isSelfBet
        ? 'You'
        : (entry.bettorUsername ?? 'Someone');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LWSpacing.sm),
      child: Row(
        children: [
          // Bettor avatar
          _BettorAvatar(
            avatarUrl: entry.bettorAvatarUrl,
            username: displayName,
            isSelf: entry.isSelfBet,
          ),
          const SizedBox(width: LWSpacing.md),

          // Stake icon
          Icon(stakeIcon, size: 20, color: lw.contentSecondary),
          const SizedBox(width: LWSpacing.sm),

          // Stake name
          Expanded(
            child: Text(
              entry.stakeTitle ?? 'No stake',
              style: LWTypography.regularNormalRegular.copyWith(
                color: entry.stakeTitle != null
                    ? lw.contentPrimary
                    : lw.contentSecondary,
              ),
            ),
          ),

          // ⋮ placeholder (no action for MLP)
          Icon(Icons.more_vert_rounded, size: 20, color: lw.borderSubtle),
        ],
      ),
    );
  }
}

class _BettorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool isSelf;
  const _BettorAvatar({
    required this.avatarUrl,
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
          color: LWColors.skyBase.withValues(alpha: 0.15),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.star_rounded,
            size: 18, color: LWColors.skyBase),
      );
    }

    if (avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
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
    Color(0xFF80D8F0), // blue
    Color(0xFFFFD54F), // yellow
    Color(0xFFFF8A80), // pink/red
    Color(0xFFA5D6A7), // green
    Color(0xFFCE93D8), // purple
  ];

  void draw(Canvas canvas, Size size_, double progress) {
    final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (t <= 0) return;

    final x = xFraction * size_.width;
    final y = -40 + t * speed * (size_.height + 80);
    final opacity = t < 0.8 ? 1.0 : (1.0 - t) / 0.2;
    final rotation = t * math.pi * 4 * speed;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
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

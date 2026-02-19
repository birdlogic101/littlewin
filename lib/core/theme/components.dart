import 'package:flutter/material.dart';
import 'tokens/spacing.dart';
import 'tokens/radius.dart';
import 'tokens/typography.dart';
import 'tokens/elevation.dart';

/// Widget-level design constants for Littlewin.
///
/// These are **not** theme-aware colours — for colours always use
/// [LWThemeExtension]. This class captures fixed sizing, padding, and
/// text-style decisions so individual widgets never hard-code magic numbers.
///
/// Usage (import only `design_system.dart`, never this file directly):
/// ```dart
/// padding: LWComponents.button.contentPadding
/// diameter: LWComponents.streakRing.diameterMd
/// ```
abstract class LWComponents {
  LWComponents._();

  static const button = _Button();
  static const card = _Card();
  static const runCard = _RunCard();
  static const inputField = _InputField();
  static const badge = _Badge();
  static const bottomNav = _BottomNav();
  static const avatar = _Avatar();
  static const streakRing = _StreakRing();
  static const betChip = _BetChip();
  static const modal = _Modal();
}

// ── Button ────────────────────────────────────────────────────────────────

class _Button {
  const _Button();

  /// Minimum tappable height (48dp rule).
  double get height => 48.0;

  /// Horizontal content padding inside the button.
  EdgeInsets get contentPadding => const EdgeInsets.symmetric(
        horizontal: LWSpacing.xxl,
        vertical: LWSpacing.lg,
      );

  /// Corner radius for the standard pill-shaped button.
  double get radius => LWRadius.pill;

  /// Corner radius for a compact/square button (e.g. icon button).
  double get radiusCompact => LWRadius.sm;

  TextStyle get labelStyle => LWTypography.regularNormalBold;

  TextStyle get labelSmallStyle => LWTypography.smallNormalMedium;
}

// ── Card ─────────────────────────────────────────────────────────────────

class _Card {
  const _Card();

  EdgeInsets get padding => const EdgeInsets.all(LWSpacing.lg);

  EdgeInsets get margin => const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.sm,
      );

  double get radius => LWRadius.md;
  double get elevation => LWElevation.none;
}

// ── Run Card (Explore feed card) ─────────────────────────────────────────

class _RunCard {
  const _RunCard();

  EdgeInsets get padding => const EdgeInsets.all(LWSpacing.lg);

  EdgeInsets get margin => const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.sm,
      );

  double get radius => LWRadius.md;
  double get elevation => LWElevation.none;

  /// Diameter of the small streak ring shown inside a run card.
  double get streakRingDiameter => 44.0;

  /// Avatar shown on the run card.
  double get avatarSize => 36.0;

  /// Small action icon button size (bet, dismiss).
  double get actionIconSize => 20.0;

  TextStyle get titleStyle => LWTypography.regularNormalBold;
  TextStyle get metaStyle => LWTypography.tinyNormalRegular;
  TextStyle get streakLabelStyle => LWTypography.tinyNoneBold;
}

// ── Input Field ──────────────────────────────────────────────────────────

class _InputField {
  const _InputField();

  double get height => 52.0;
  double get radius => LWRadius.xs;

  EdgeInsets get contentPadding => const EdgeInsets.symmetric(
        horizontal: LWSpacing.lg,
        vertical: LWSpacing.md,
      );

  TextStyle get labelStyle => LWTypography.smallNormalRegular;
  TextStyle get hintStyle => LWTypography.regularNormalRegular;
  TextStyle get inputStyle => LWTypography.regularNormalRegular;
}

// ── Badge ────────────────────────────────────────────────────────────────

class _Badge {
  const _Badge();

  double get size => 20.0;
  double get sizeSmall => 14.0;
  double get radius => LWRadius.pill;

  EdgeInsets get padding => const EdgeInsets.symmetric(
        horizontal: LWSpacing.xs,
        vertical: 2.0,
      );

  TextStyle get labelStyle => LWTypography.tinyNoneBold;
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────

class _BottomNav {
  const _BottomNav();

  double get height => 64.0;
  double get iconSize => 24.0;
  double get iconSizeActive => 26.0;
  double get dotSize => 4.0;    // active indicator dot
}

// ── Avatar ───────────────────────────────────────────────────────────────

class _Avatar {
  const _Avatar();

  /// XS — used inline in text / notifications (24dp).
  double get xs => 24.0;

  /// SM — used in run cards, list rows (32dp).
  double get sm => 32.0;

  /// MD — used in profile headers, people cards (48dp).
  double get md => 48.0;

  /// LG — used in profile screen (64dp).
  double get lg => 64.0;

  /// XL — used in settings / onboarding (96dp).
  double get xl => 96.0;

  double get radius => LWRadius.pill; // always circular
}

// ── Streak Ring ──────────────────────────────────────────────────────────

class _StreakRing {
  const _StreakRing();

  /// Stroke width of the ring arc.
  double get trackWidth => 5.0;

  /// Small ring — inside run cards.
  double get diameterSm => 44.0;

  /// Medium ring — check-in screen list item.
  double get diameterMd => 64.0;

  /// Large ring — check-in screen hero / run detail.
  double get diameterLg => 120.0;
}

// ── Bet Chip ─────────────────────────────────────────────────────────────

class _BetChip {
  const _BetChip();

  double get height => 32.0;
  double get radius => LWRadius.pill;

  EdgeInsets get padding => const EdgeInsets.symmetric(
        horizontal: LWSpacing.md,
        vertical: LWSpacing.xs,
      );

  TextStyle get labelStyle => LWTypography.smallNoneMedium;
}

// ── Modal / Bottom Sheet ─────────────────────────────────────────────────

class _Modal {
  const _Modal();

  double get topRadius => LWRadius.lg;
  double get dragHandleWidth => 40.0;
  double get dragHandleHeight => 4.0;
  double get dragHandleRadius => 2.0;

  EdgeInsets get contentPadding => const EdgeInsets.fromLTRB(
        LWSpacing.xl,
        LWSpacing.md,
        LWSpacing.xl,
        LWSpacing.xxl,
      );
}

import 'package:flutter/material.dart';
import 'tokens/colors.dart';

/// Semantic, theme-aware color roles for Littlewin.
///
/// Access via [Theme.of(context).extension<LWThemeExtension>()!]
/// or the helper: [LWThemeExtension.of(context)].
///
/// Widgets must NEVER reference raw [LWColors] primitives for
/// theme-sensitive decisions — use this extension instead.
class LWThemeExtension extends ThemeExtension<LWThemeExtension> {
  // ── Surfaces & Backgrounds ───────────────────────────────────────────────
  /// Main scaffold / page background.
  final Color backgroundApp;

  /// Default card / list-item background.
  final Color backgroundCard;

  /// Bottom sheet and dialog background.
  final Color backgroundSheet;

  /// Modal scrim (semi-transparent overlay behind modals).
  final Color backgroundOverlay;

  // ── Content (Text & Icons) ───────────────────────────────────────────────
  /// High-emphasis text and icons (headings, primary body).
  final Color contentPrimary;

  /// Medium-emphasis text and icons (captions, hints, metadata).
  final Color contentSecondary;

  /// Disabled text and icons.
  final Color contentDisabled;

  /// Text or icon placed ON a coloured/dark surface (always white-ish).
  final Color contentInverse;

  // ── Brand ────────────────────────────────────────────────────────────────
  /// Primary brand colour (blue). Used on CTA buttons, links, active icons.
  final Color brandPrimary;

  /// Content colour on top of [brandPrimary] surfaces.
  final Color onBrandPrimary;

  /// Subtle brand-tinted surface (e.g. selected chip background).
  final Color brandSubtle;

  // ── Accent ───────────────────────────────────────────────────────────────
  /// Accent highlight colour (yellow/gold). Used for bets, highlights.
  final Color accentDefault;

  /// Content colour on top of [accentDefault] surfaces.
  final Color onAccent;

  // ── Semantic Feedback ────────────────────────────────────────────────────
  /// Positive / success state (check-in done, streak active, bet won).
  final Color feedbackPositive;

  /// Subtle positive surface (e.g. success toast background).
  final Color feedbackPositiveSubtle;

  /// Negative / error state (bet lost, validation error).
  final Color feedbackNegative;

  /// Subtle negative surface (e.g. error toast background).
  final Color feedbackNegativeSubtle;

  // ── Streak & Gamification ────────────────────────────────────────────────
  /// Unlit portion of the streak ring (track).
  final Color streakRingTrack;

  /// Active / filled portion of the streak ring.
  final Color streakRingFill;

  /// Glow colour used on milestone celebrations (7 / 14 / 21 days).
  final Color streakMilestoneGlow;

  // ── Navigation Bar ───────────────────────────────────────────────────────
  final Color navBackground;
  final Color navIconActive;
  final Color navIconInactive;

  // ── Borders & Dividers ───────────────────────────────────────────────────
  /// Subtle divider lines between list items.
  final Color borderSubtle;

  /// Card or input field outlines.
  final Color borderStrong;

  /// Focus ring on interactive elements.
  final Color borderFocus;

  // ── Interactive States ───────────────────────────────────────────────────
  /// Default background for ghost-style interactive areas.
  final Color interactiveDefault;

  /// Background when an interactive area is pressed.
  final Color interactivePressed;

  // ─────────────────────────────────────────────────────────────────────────

  const LWThemeExtension({
    required this.backgroundApp,
    required this.backgroundCard,
    required this.backgroundSheet,
    required this.backgroundOverlay,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentDisabled,
    required this.contentInverse,
    required this.brandPrimary,
    required this.onBrandPrimary,
    required this.brandSubtle,
    required this.accentDefault,
    required this.onAccent,
    required this.feedbackPositive,
    required this.feedbackPositiveSubtle,
    required this.feedbackNegative,
    required this.feedbackNegativeSubtle,
    required this.streakRingTrack,
    required this.streakRingFill,
    required this.streakMilestoneGlow,
    required this.navBackground,
    required this.navIconActive,
    required this.navIconInactive,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.interactiveDefault,
    required this.interactivePressed,
  });

  // ── Convenience accessor ─────────────────────────────────────────────────
  static LWThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<LWThemeExtension>()!;

  // ── Light ────────────────────────────────────────────────────────────────
  static const light = LWThemeExtension(
    // Surfaces
    backgroundApp: LWColors.skyWhite,
    backgroundCard: LWColors.skyWhite,
    backgroundSheet: LWColors.skyWhite,
    backgroundOverlay: Color(0x4D0F1113), // inkDarkest @30%

    // Content
    contentPrimary: LWColors.inkDarkest,
    contentSecondary: LWColors.inkLight,
    contentDisabled: LWColors.skyDark,
    contentInverse: LWColors.skyWhite,

    // Brand
    brandPrimary: LWColors.primaryBase,
    onBrandPrimary: LWColors.skyWhite,
    brandSubtle: LWColors.primaryLightest,

    // Accent
    accentDefault: LWColors.accentBase,
    onAccent: LWColors.inkDarkest,

    // Feedback
    feedbackPositive: LWColors.positiveBase,
    feedbackPositiveSubtle: LWColors.positiveLightest,
    feedbackNegative: LWColors.negativeBase,
    feedbackNegativeSubtle: LWColors.negativeLightest,

    // Streak
    streakRingTrack: LWColors.skyLight,
    streakRingFill: LWColors.energyBase,
    streakMilestoneGlow: LWColors.growthLight,

    // Nav
    navBackground: LWColors.skyWhite,
    navIconActive: LWColors.inkDarkest,
    navIconInactive: LWColors.inkLight,

    // Borders
    borderSubtle: LWColors.skyLight,
    borderStrong: LWColors.skyBase,
    borderFocus: LWColors.primaryBase,

    // Interactive
    interactiveDefault: LWColors.skySurface,
    interactivePressed: LWColors.skyLighter,
  );

  // ── Dark ─────────────────────────────────────────────────────────────────
  static const dark = LWThemeExtension(
    // Surfaces
    backgroundApp: LWColors.inkDarkest,
    backgroundCard: LWColors.inkDark,
    backgroundSheet: LWColors.inkDarker,
    backgroundOverlay: Color(0x73000000), // black @45%

    // Content
    contentPrimary: LWColors.skyWhite,
    contentSecondary: LWColors.inkLighter,
    contentDisabled: LWColors.inkBase,
    contentInverse: LWColors.inkDarkest,

    // Brand
    brandPrimary: LWColors.primaryBase,
    onBrandPrimary: LWColors.skyWhite,
    brandSubtle: Color(0xFF1A3A52), // dark tint of primaryBase

    // Accent
    accentDefault: LWColors.accentBase,
    onAccent: LWColors.inkDarkest,

    // Feedback
    feedbackPositive: LWColors.positiveBase,
    feedbackPositiveSubtle: Color(0xFF1A3D28),
    feedbackNegative: LWColors.negativeBase,
    feedbackNegativeSubtle: Color(0xFF3D1E18),

    // Streak
    streakRingTrack: LWColors.inkBase,
    streakRingFill: LWColors.energyBase,
    streakMilestoneGlow: LWColors.growthBase,

    // Nav
    navBackground: LWColors.inkDarkest,
    navIconActive: LWColors.skyWhite,
    navIconInactive: LWColors.inkLighter,

    // Borders
    borderSubtle: LWColors.inkDark,
    borderStrong: LWColors.inkBase,
    borderFocus: LWColors.primaryLight,

    // Interactive
    interactiveDefault: LWColors.inkDark,
    interactivePressed: LWColors.inkBase,
  );

  // ── ThemeExtension boilerplate ───────────────────────────────────────────
  @override
  LWThemeExtension copyWith({
    Color? backgroundApp,
    Color? backgroundCard,
    Color? backgroundSheet,
    Color? backgroundOverlay,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentDisabled,
    Color? contentInverse,
    Color? brandPrimary,
    Color? onBrandPrimary,
    Color? brandSubtle,
    Color? accentDefault,
    Color? onAccent,
    Color? feedbackPositive,
    Color? feedbackPositiveSubtle,
    Color? feedbackNegative,
    Color? feedbackNegativeSubtle,
    Color? streakRingTrack,
    Color? streakRingFill,
    Color? streakMilestoneGlow,
    Color? navBackground,
    Color? navIconActive,
    Color? navIconInactive,
    Color? borderSubtle,
    Color? borderStrong,
    Color? borderFocus,
    Color? interactiveDefault,
    Color? interactivePressed,
  }) {
    return LWThemeExtension(
      backgroundApp: backgroundApp ?? this.backgroundApp,
      backgroundCard: backgroundCard ?? this.backgroundCard,
      backgroundSheet: backgroundSheet ?? this.backgroundSheet,
      backgroundOverlay: backgroundOverlay ?? this.backgroundOverlay,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      contentDisabled: contentDisabled ?? this.contentDisabled,
      contentInverse: contentInverse ?? this.contentInverse,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      onBrandPrimary: onBrandPrimary ?? this.onBrandPrimary,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      accentDefault: accentDefault ?? this.accentDefault,
      onAccent: onAccent ?? this.onAccent,
      feedbackPositive: feedbackPositive ?? this.feedbackPositive,
      feedbackPositiveSubtle:
          feedbackPositiveSubtle ?? this.feedbackPositiveSubtle,
      feedbackNegative: feedbackNegative ?? this.feedbackNegative,
      feedbackNegativeSubtle:
          feedbackNegativeSubtle ?? this.feedbackNegativeSubtle,
      streakRingTrack: streakRingTrack ?? this.streakRingTrack,
      streakRingFill: streakRingFill ?? this.streakRingFill,
      streakMilestoneGlow: streakMilestoneGlow ?? this.streakMilestoneGlow,
      navBackground: navBackground ?? this.navBackground,
      navIconActive: navIconActive ?? this.navIconActive,
      navIconInactive: navIconInactive ?? this.navIconInactive,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      interactiveDefault: interactiveDefault ?? this.interactiveDefault,
      interactivePressed: interactivePressed ?? this.interactivePressed,
    );
  }

  @override
  LWThemeExtension lerp(ThemeExtension<LWThemeExtension>? other, double t) {
    if (other is! LWThemeExtension) return this;
    return LWThemeExtension(
      backgroundApp: Color.lerp(backgroundApp, other.backgroundApp, t)!,
      backgroundCard: Color.lerp(backgroundCard, other.backgroundCard, t)!,
      backgroundSheet: Color.lerp(backgroundSheet, other.backgroundSheet, t)!,
      backgroundOverlay:
          Color.lerp(backgroundOverlay, other.backgroundOverlay, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary:
          Color.lerp(contentSecondary, other.contentSecondary, t)!,
      contentDisabled: Color.lerp(contentDisabled, other.contentDisabled, t)!,
      contentInverse: Color.lerp(contentInverse, other.contentInverse, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      onBrandPrimary: Color.lerp(onBrandPrimary, other.onBrandPrimary, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      accentDefault: Color.lerp(accentDefault, other.accentDefault, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      feedbackPositive:
          Color.lerp(feedbackPositive, other.feedbackPositive, t)!,
      feedbackPositiveSubtle:
          Color.lerp(feedbackPositiveSubtle, other.feedbackPositiveSubtle, t)!,
      feedbackNegative:
          Color.lerp(feedbackNegative, other.feedbackNegative, t)!,
      feedbackNegativeSubtle:
          Color.lerp(feedbackNegativeSubtle, other.feedbackNegativeSubtle, t)!,
      streakRingTrack: Color.lerp(streakRingTrack, other.streakRingTrack, t)!,
      streakRingFill: Color.lerp(streakRingFill, other.streakRingFill, t)!,
      streakMilestoneGlow:
          Color.lerp(streakMilestoneGlow, other.streakMilestoneGlow, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navIconActive: Color.lerp(navIconActive, other.navIconActive, t)!,
      navIconInactive: Color.lerp(navIconInactive, other.navIconInactive, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      interactiveDefault:
          Color.lerp(interactiveDefault, other.interactiveDefault, t)!,
      interactivePressed:
          Color.lerp(interactivePressed, other.interactivePressed, t)!,
    );
  }
}

import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/radius.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';

class LWThemeExtension extends ThemeExtension<LWThemeExtension> {
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;
  
  // Specific Component Colors
  final Color cardBackground;
  final Color navBarBackground;
  final Color navBarIconSelected;
  final Color navBarIconUnselected;
  final Color streakRingBase;
  final Color streakRingActive;

  const LWThemeExtension({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.cardBackground,
    required this.navBarBackground,
    required this.navBarIconSelected,
    required this.navBarIconUnselected,
    required this.streakRingBase,
    required this.streakRingActive,
  });

  @override
  ThemeExtension<LWThemeExtension> copyWith({
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? onSurface,
    Color? background,
    Color? onBackground,
    Color? error,
    Color? onError,
    Color? cardBackground,
    Color? navBarBackground,
    Color? navBarIconSelected,
    Color? navBarIconUnselected,
    Color? streakRingBase,
    Color? streakRingActive,
  }) {
    return LWThemeExtension(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      cardBackground: cardBackground ?? this.cardBackground,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      navBarIconSelected: navBarIconSelected ?? this.navBarIconSelected,
      navBarIconUnselected: navBarIconUnselected ?? this.navBarIconUnselected,
      streakRingBase: streakRingBase ?? this.streakRingBase,
      streakRingActive: streakRingActive ?? this.streakRingActive,
    );
  }

  @override
  ThemeExtension<LWThemeExtension> lerp(
      ThemeExtension<LWThemeExtension>? other, double t) {
    if (other is! LWThemeExtension) {
      return this;
    }
    return LWThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t)!,
      navBarIconSelected: Color.lerp(navBarIconSelected, other.navBarIconSelected, t)!,
      navBarIconUnselected: Color.lerp(navBarIconUnselected, other.navBarIconUnselected, t)!,
      streakRingBase: Color.lerp(streakRingBase, other.streakRingBase, t)!,
      streakRingActive: Color.lerp(streakRingActive, other.streakRingActive, t)!,
    );
  }

  static const light = LWThemeExtension(
    primary: LWColors.primaryBase,
    onPrimary: LWColors.skyWhite,
    surface: LWColors.skySurface,
    onSurface: LWColors.inkDarkest,
    background: LWColors.skyWhite,
    onBackground: LWColors.inkDarkest,
    error: LWColors.negativeBase,
    onError: LWColors.skyWhite,
    cardBackground: LWColors.skyWhite,
    navBarBackground: LWColors.skyWhite,
    navBarIconSelected: LWColors.inkDarkest,
    navBarIconUnselected: LWColors.inkLight, // Grey
    streakRingBase: LWColors.skyLight, // Ring background
    streakRingActive: LWColors.energyBase, // Yellow/Gold
  );

  static const dark = LWThemeExtension(
    primary: LWColors.primaryBase, // Or primaryLight for dark mode
    onPrimary: LWColors.skyWhite,
    surface: LWColors.inkDark,
    onSurface: LWColors.skyWhite,
    background: LWColors.inkDarkest,
    onBackground: LWColors.skyWhite,
    error: LWColors.negativeBase,
    onError: LWColors.skyWhite,
    cardBackground: LWColors.inkDark, // Surface
    navBarBackground: LWColors.inkDarkest,
    navBarIconSelected: LWColors.skyWhite,
    navBarIconUnselected: LWColors.inkLight,
    streakRingBase: LWColors.inkBase,
    streakRingActive: LWColors.energyBase,
  );
}

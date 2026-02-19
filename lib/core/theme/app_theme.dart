import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/radius.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';
import 'lw_theme_extension.dart';

class AppTheme {
  // Light Theme (Clean, White Background)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: LWColors.primaryBase,
    scaffoldBackgroundColor: LWColors.skyWhite,
    extensions: const [LWThemeExtension.light],
    colorScheme: const ColorScheme.light(
      primary: LWColors.primaryBase,
      secondary: LWColors.accentBase,
      surface: LWColors.skyWhite,
      error: LWColors.negativeBase,
      onPrimary: LWColors.skyWhite,
      onSecondary: LWColors.inkDarkest,
      onSurface: LWColors.inkDarkest,
      onError: LWColors.skyWhite,
    ),
    textTheme: TextTheme(
      displayLarge: LWTypography.title1.copyWith(color: LWColors.inkDarkest),
      displayMedium: LWTypography.title2.copyWith(color: LWColors.inkDarkest),
      displaySmall: LWTypography.title3.copyWith(color: LWColors.inkDarkest),
      headlineMedium: LWTypography.title4.copyWith(color: LWColors.inkDarkest),
      bodyLarge: LWTypography.regularNormalRegular.copyWith(color: LWColors.inkDarkest),
      bodyMedium: LWTypography.smallNormalRegular.copyWith(color: LWColors.inkDarkest), // 14px
      labelLarge: LWTypography.regularNormalMedium.copyWith(color: LWColors.inkDarkest), // Button text
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LWColors.skyWhite,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: LWColors.inkDarkest),
      titleTextStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: LWColors.inkDarkest,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LWColors.skyWhite,
      selectedItemColor: LWColors.inkDarkest,
      unselectedItemColor: LWColors.inkLight,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LWColors.skyWhite, // White pill button
        foregroundColor: LWColors.inkDarkest, // Black text
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LWRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LWSpacing.xxl, 
          vertical: LWSpacing.lg, // 16px vertical padding for ~48px height
        ),
        textStyle: LWTypography.regularNormalBold, // Bold text for buttons
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LWColors.skySurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWRadius.xs),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWRadius.xs),
        borderSide: const BorderSide(color: LWColors.primaryBase, width: 2),
      ),
      contentPadding: const EdgeInsets.all(LWSpacing.lg),
      labelStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        color: LWColors.inkLighter,
      ),
      hintStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        color: LWColors.inkLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: LWColors.skyWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWRadius.md),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: LWSpacing.sm, 
        horizontal: LWSpacing.lg,
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: LWColors.primaryBase,
    scaffoldBackgroundColor: LWColors.inkDarkest,
    extensions: const [LWThemeExtension.dark],
    colorScheme: const ColorScheme.dark(
      primary: LWColors.primaryBase,
      secondary: LWColors.accentBase,
      surface: LWColors.inkDark,
      error: LWColors.negativeBase,
      onPrimary: LWColors.skyWhite,
      onSecondary: LWColors.inkDarkest,
      onSurface: LWColors.skyWhite,
      onError: LWColors.skyWhite,
    ),
    textTheme: TextTheme(
      displayLarge: LWTypography.title1.copyWith(color: LWColors.skyWhite),
      displayMedium: LWTypography.title2.copyWith(color: LWColors.skyWhite),
      displaySmall: LWTypography.title3.copyWith(color: LWColors.skyWhite),
      headlineMedium: LWTypography.title4.copyWith(color: LWColors.skyWhite),
      bodyLarge: LWTypography.regularNormalRegular.copyWith(color: LWColors.skyWhite),
      bodyMedium: LWTypography.smallNormalRegular.copyWith(color: LWColors.skyWhite),
      labelLarge: LWTypography.regularNormalMedium.copyWith(color: LWColors.skyWhite),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LWColors.inkDarkest,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: LWColors.skyWhite),
      titleTextStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: LWColors.skyWhite,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LWColors.inkDarkest,
      selectedItemColor: LWColors.skyWhite,
      unselectedItemColor: LWColors.inkLight,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LWColors.primaryBase,
        foregroundColor: LWColors.skyWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LWRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LWSpacing.xxl, 
          vertical: LWSpacing.lg,
        ),
        textStyle: LWTypography.regularNormalMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LWColors.inkDark, // Surface
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWRadius.xs),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWRadius.xs),
        borderSide: const BorderSide(color: LWColors.primaryBase, width: 2), // thick stroke
      ),
      contentPadding: const EdgeInsets.all(LWSpacing.lg),
      labelStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        color: LWColors.inkLighter,
      ),
      hintStyle: TextStyle(
        fontFamily: LWTypography.fontFamilyPrimary,
        color: LWColors.inkLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: LWColors.inkDark, // Surface
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWRadius.md),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: LWSpacing.sm, 
        horizontal: LWSpacing.lg,
      ),
    ),
  );
}

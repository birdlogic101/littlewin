import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/radius.dart';
import 'tokens/spacing.dart';
import 'tokens/typography.dart';
import 'tokens/elevation.dart';
import 'lw_theme_extension.dart';
import 'components.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ───────────────────────────────────────────────────────────
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
      bodyLarge: LWTypography.regularNormalRegular
          .copyWith(color: LWColors.inkDarkest),
      bodyMedium: LWTypography.smallNormalRegular
          .copyWith(color: LWColors.inkDarkest),
      labelLarge: LWTypography.regularNormalMedium
          .copyWith(color: LWColors.inkDarkest),
      labelSmall: LWTypography.tinyNoneRegular
          .copyWith(color: LWColors.inkLight),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: LWColors.skyWhite,
      elevation: LWElevation.none,
      centerTitle: true,
      iconTheme: const IconThemeData(color: LWColors.inkDarkest),
      titleTextStyle: LWTypography.title4.copyWith(color: LWColors.inkDarkest),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: LWColors.skyWhite,
      selectedItemColor: LWColors.inkDarkest,
      unselectedItemColor: LWColors.inkLight,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: LWElevation.none,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LWColors.skyWhite,
        foregroundColor: LWColors.inkDarkest,
        elevation: LWElevation.none,
        minimumSize: Size(double.infinity, LWComponents.button.height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LWComponents.button.radius),
        ),
        padding: LWComponents.button.contentPadding,
        textStyle: LWComponents.button.labelStyle,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LWColors.skySurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.skyBase, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.primaryBase, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.negativeBase, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.negativeBase, width: 2),
      ),
      contentPadding: LWComponents.inputField.contentPadding,
      labelStyle: LWComponents.inputField.labelStyle
          .copyWith(color: LWColors.inkLighter),
      hintStyle: LWComponents.inputField.hintStyle
          .copyWith(color: LWColors.inkLight),
    ),

    cardTheme: CardThemeData(
      color: LWColors.skyWhite,
      elevation: LWComponents.card.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWComponents.card.radius),
      ),
      margin: LWComponents.card.margin,
    ),

    dividerTheme: const DividerThemeData(
      color: LWColors.skyLight,
      thickness: 1,
      space: LWSpacing.lg,
    ),

    chipTheme: ChipThemeData(
      padding: LWComponents.betChip.padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWComponents.betChip.radius),
      ),
      labelStyle: LWComponents.betChip.labelStyle
          .copyWith(color: LWColors.inkDarkest),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: LWColors.inkDark,
      contentTextStyle: LWTypography.smallNormalRegular
          .copyWith(color: LWColors.skyWhite),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: LWColors.skyWhite,
      elevation: LWElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LWComponents.modal.topRadius),
        ),
      ),
    ),
  );

  // ── Dark Theme ────────────────────────────────────────────────────────────
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
      bodyLarge:
          LWTypography.regularNormalRegular.copyWith(color: LWColors.skyWhite),
      bodyMedium:
          LWTypography.smallNormalRegular.copyWith(color: LWColors.skyWhite),
      labelLarge:
          LWTypography.regularNormalMedium.copyWith(color: LWColors.skyWhite),
      labelSmall:
          LWTypography.tinyNoneRegular.copyWith(color: LWColors.inkLighter),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: LWColors.inkDarkest,
      elevation: LWElevation.none,
      centerTitle: true,
      iconTheme: const IconThemeData(color: LWColors.skyWhite),
      titleTextStyle: LWTypography.title4.copyWith(color: LWColors.skyWhite),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: LWColors.inkDarkest,
      selectedItemColor: LWColors.skyWhite,
      unselectedItemColor: LWColors.inkLighter,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: LWElevation.none,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LWColors.primaryBase,
        foregroundColor: LWColors.skyWhite,
        elevation: LWElevation.none,
        minimumSize: Size(double.infinity, LWComponents.button.height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LWComponents.button.radius),
        ),
        padding: LWComponents.button.contentPadding,
        textStyle: LWComponents.button.labelStyle,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LWColors.inkDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.inkBase, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.negativeBase, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LWComponents.inputField.radius),
        borderSide: const BorderSide(color: LWColors.negativeBase, width: 2),
      ),
      contentPadding: LWComponents.inputField.contentPadding,
      labelStyle: LWComponents.inputField.labelStyle
          .copyWith(color: LWColors.inkLighter),
      hintStyle: LWComponents.inputField.hintStyle
          .copyWith(color: LWColors.inkLight),
    ),

    cardTheme: CardThemeData(
      color: LWColors.inkDark,
      elevation: LWComponents.card.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWComponents.card.radius),
      ),
      margin: LWComponents.card.margin,
    ),

    dividerTheme: const DividerThemeData(
      color: LWColors.inkDark,
      thickness: 1,
      space: LWSpacing.lg,
    ),

    chipTheme: ChipThemeData(
      padding: LWComponents.betChip.padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWComponents.betChip.radius),
      ),
      labelStyle: LWComponents.betChip.labelStyle
          .copyWith(color: LWColors.skyWhite),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: LWColors.inkBase,
      contentTextStyle: LWTypography.smallNormalRegular
          .copyWith(color: LWColors.skyWhite),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LWRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: LWColors.inkDarker,
      elevation: LWElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LWComponents.modal.topRadius),
        ),
      ),
    ),
  );
}

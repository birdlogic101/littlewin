import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LWTypography {
  static const String fontFamilyPrimary = 'Rubik';
  
  static TextStyle get _baseStyle => GoogleFonts.rubik();

  static TextStyle get title1 => _baseStyle.copyWith(fontSize: 48, height: 56 / 48, fontWeight: FontWeight.bold);
  static TextStyle get title2 => _baseStyle.copyWith(fontSize: 40, height: 44 / 40, fontWeight: FontWeight.bold);
  static TextStyle get title3 => _baseStyle.copyWith(fontSize: 32, height: 36 / 32, fontWeight: FontWeight.bold);
  static TextStyle get title4 => _baseStyle.copyWith(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.bold);

  // Large (18px)
  static TextStyle get largeNoneBold => _baseStyle.copyWith(fontSize: 18, height: 18 / 18, fontWeight: FontWeight.bold);
  static TextStyle get largeNoneMedium => _baseStyle.copyWith(fontSize: 18, height: 18 / 18, fontWeight: FontWeight.w500);
  static TextStyle get largeNoneRegular => _baseStyle.copyWith(fontSize: 18, height: 18 / 18, fontWeight: FontWeight.w400);

  static TextStyle get largeTightBold => _baseStyle.copyWith(fontSize: 18, height: 20 / 18, fontWeight: FontWeight.bold);
  static TextStyle get largeTightMedium => _baseStyle.copyWith(fontSize: 18, height: 20 / 18, fontWeight: FontWeight.w500);
  static TextStyle get largeTightRegular => _baseStyle.copyWith(fontSize: 18, height: 20 / 18, fontWeight: FontWeight.w400);

  static TextStyle get largeNormalBold => _baseStyle.copyWith(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.bold);
  static TextStyle get largeNormalMedium => _baseStyle.copyWith(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w500);
  static TextStyle get largeNormalRegular => _baseStyle.copyWith(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w400);

  // Regular (16px)
  static TextStyle get regularNoneBold => _baseStyle.copyWith(fontSize: 16, height: 16 / 16, fontWeight: FontWeight.bold);
  static TextStyle get regularNoneMedium => _baseStyle.copyWith(fontSize: 16, height: 16 / 16, fontWeight: FontWeight.w500);
  static TextStyle get regularNoneRegular => _baseStyle.copyWith(fontSize: 16, height: 16 / 16, fontWeight: FontWeight.w400);

  static TextStyle get regularTightBold => _baseStyle.copyWith(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.bold);
  static TextStyle get regularTightMedium => _baseStyle.copyWith(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w500);
  static TextStyle get regularTightRegular => _baseStyle.copyWith(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w400);
  
  static TextStyle get regularNormalBold => _baseStyle.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.bold);
  static TextStyle get regularNormalMedium => _baseStyle.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500);
  static TextStyle get regularNormalRegular => _baseStyle.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400);

  // Small (14px)
  static TextStyle get smallNoneBold => _baseStyle.copyWith(fontSize: 14, height: 14 / 14, fontWeight: FontWeight.bold);
  static TextStyle get smallNoneMedium => _baseStyle.copyWith(fontSize: 14, height: 14 / 14, fontWeight: FontWeight.w500);
  static TextStyle get smallNoneRegular => _baseStyle.copyWith(fontSize: 14, height: 14 / 14, fontWeight: FontWeight.w400);
  
  static TextStyle get smallTightBold => _baseStyle.copyWith(fontSize: 14, height: 16 / 14, fontWeight: FontWeight.bold);
  static TextStyle get smallTightMedium => _baseStyle.copyWith(fontSize: 14, height: 16 / 14, fontWeight: FontWeight.w500);
  static TextStyle get smallTightRegular => _baseStyle.copyWith(fontSize: 14, height: 16 / 14, fontWeight: FontWeight.w400);

  static TextStyle get smallNormalBold => _baseStyle.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.bold);
  static TextStyle get smallNormalMedium => _baseStyle.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500);
  static TextStyle get smallNormalRegular => _baseStyle.copyWith(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400);

  // Tiny (12px)
  static TextStyle get tinyNoneBold => _baseStyle.copyWith(fontSize: 12, height: 12 / 12, fontWeight: FontWeight.bold);
  static TextStyle get tinyNoneMedium => _baseStyle.copyWith(fontSize: 12, height: 12 / 12, fontWeight: FontWeight.w500);
  static TextStyle get tinyNoneRegular => _baseStyle.copyWith(fontSize: 12, height: 12 / 12, fontWeight: FontWeight.w400);

  static TextStyle get tinyTightBold => _baseStyle.copyWith(fontSize: 12, height: 14 / 12, fontWeight: FontWeight.bold);
  static TextStyle get tinyTightMedium => _baseStyle.copyWith(fontSize: 12, height: 14 / 12, fontWeight: FontWeight.w500);
  static TextStyle get tinyTightRegular => _baseStyle.copyWith(fontSize: 12, height: 14 / 12, fontWeight: FontWeight.w400);

  static TextStyle get tinyNormalBold => _baseStyle.copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.bold);
  static TextStyle get tinyNormalMedium => _baseStyle.copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500);
  static TextStyle get tinyNormalRegular => _baseStyle.copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400);
}

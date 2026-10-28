import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blush, cream, and script — the Kehlo product theme.
abstract final class Bloom {
  static const Color bg = Color(0xFFFBF6F4);
  static const Color bgDeep = Color(0xFFF3EBE8);
  static const Color canvas = Color(0xFFE9DDD8);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF2B2426);
  static const Color inkSoft = Color(0xFF6E6568);
  static const Color mute = Color(0xFFA39A9C);
  static const Color line = Color(0xFFF0E4E1);
  static const Color pink = Color(0xFFE57C94);
  static const Color pinkDeep = Color(0xFFD46882);
  static const Color pinkSoft = Color(0xFFFBECEF);
  static const Color dot = Color(0xFFE6D5D2);
  static const Color shadow = Color(0x1460444A);

  static const Color sweetFg = Color(0xFFE57C94);
  static const Color sweetBg = Color(0xFFFDECEF);
  static const Color playfulFg = Color(0xFFE0903A);
  static const Color playfulBg = Color(0xFFFFF1E4);
  static const Color confidentFg = Color(0xFF9A6BB8);
  static const Color confidentBg = Color(0xFFF4ECF8);
  static const Color thoughtfulFg = Color(0xFF6E8FBF);
  static const Color thoughtfulBg = Color(0xFFEEF3FA);
}

abstract final class BloomType {
  static TextStyle script(double size, Color color) => GoogleFonts.allura(
        fontSize: size,
        color: color,
        height: 0.95,
      );

  static TextStyle display(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        height: 1.12,
        letterSpacing: -0.5,
        color: color ?? Bloom.ink,
      );

  static TextStyle sans({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.15,
        color: color ?? Bloom.ink,
      );
}

ThemeData bloomTheme() {
  final text = GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: Bloom.ink,
    displayColor: Bloom.ink,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Bloom.bg,
    colorScheme: const ColorScheme.light(
      primary: Bloom.pink,
      onPrimary: Colors.white,
      surface: Bloom.card,
      onSurface: Bloom.ink,
    ),
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    splashColor: Bloom.pinkSoft,
    highlightColor: Colors.transparent,
    dividerColor: Bloom.line,
    appBarTheme: AppBarTheme(
      backgroundColor: Bloom.bg,
      foregroundColor: Bloom.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Bloom.ink,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Bloom.ink,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

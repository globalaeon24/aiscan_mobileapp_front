import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OySynAuthTokens {
  const OySynAuthTokens._();

  static const String logoAsset = 'assets/icons/oysyn_logo.png';

  static const Color primaryBlue = Color(0xFF3F73F6);
  static const Color linkBlue = Color(0xFF2F6BFF);
  static const Color textDark = Color(0xFF2F3B48);
  static const Color textMuted = Color(0xFF707B84);
  static const Color iconGrey = Color(0xFF737D84);
  static const Color fieldBorder = Color(0xFFD2DFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color topWash = Color(0xFFEFFBFF);
  static const Color shadowBlue = Color(0x333F73F6);

  static const double contentMaxWidth = 390;
  static const double screenHorizontalPadding = 24;
  static const double fieldHeight = 56;
  static const double fieldRadius = 12;
  static const double buttonHeight = 56;
  static const double buttonRadius = 12;
  static const double logoSize = 74;
}

class OySynTextStyles {
  const OySynTextStyles._();

  static TextStyle get welcomeTitle => GoogleFonts.dmSans(
        color: const Color(0xFF111827),
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get sectionTitle => GoogleFonts.dmSans(
        color: Colors.black,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get recentDocumentsTitle => GoogleFonts.dmSans(
        color: Colors.black,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get authLogo => GoogleFonts.dmSans(
        color: OySynAuthTokens.primaryBlue,
        fontSize: 30,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      );
}

ThemeData buildAppTheme() {
  const seedColor = OySynAuthTokens.primaryBlue;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F5FB),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OySynAuthTokens.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OySynAuthTokens.fieldRadius),
        borderSide: const BorderSide(color: OySynAuthTokens.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OySynAuthTokens.fieldRadius),
        borderSide: const BorderSide(color: OySynAuthTokens.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OySynAuthTokens.fieldRadius),
        borderSide: const BorderSide(
          color: OySynAuthTokens.primaryBlue,
          width: 1.4,
        ),
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      foregroundColor: base.colorScheme.onSurface,
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: seedColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
      color: Colors.white,
      elevation: 8,
    ),
  );
}

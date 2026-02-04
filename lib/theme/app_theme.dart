import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const seedColor = Color(0xFF4F46E5); // сине-фиолетовый акцент

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F5FB),
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
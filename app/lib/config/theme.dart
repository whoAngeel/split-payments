import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _terracotta = Color(0xFFC2573A);
const _tierraClara = Color(0xFFFAF6F3);
const _barro = Color(0xFFF0EBE7);
const _madera = Color(0xFF3A302B);
const _arena = Color(0xFF736761);
const _piedra = Color(0xFFCBC5C1);

const colorScheme = ColorScheme(
  brightness: Brightness.light,

  // Primary: Terracota Cocido — the sole accent, ≤10% per screen
  primary: _terracotta,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFCE4DD),
  onPrimaryContainer: Color(0xFF6B1D0A),

  // Secondary: muted warm stone — barely distinguishable, accent is the star
  secondary: Color(0xFFE8DED7),
  onSecondary: _madera,
  secondaryContainer: Color(0xFFF2EBE5),
  onSecondaryContainer: Color(0xFF4A3E36),

  // Tertiary: muted sage — for rare tertiary signals (never decorative)
  tertiary: Color(0xFF6B7B6A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFDDE8DC),
  onTertiaryContainer: Color(0xFF1A2A19),

  // Error
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),

  // Neutral surfaces
  surface: _tierraClara,
  onSurface: _madera,
  surfaceContainerHighest: _barro,
  surfaceContainerHigh: Color(0xFFF5F1ED),
  surfaceContainer: Color(0xFFF2EDE9),
  surfaceContainerLow: Color(0xFFF8F4F1),
  surfaceContainerLowest: Color(0xFFFFFFFF),

  onSurfaceVariant: _arena,
  outline: _piedra,
  outlineVariant: Color(0xFFDED9D5),

  scrim: Color(0xFF000000),
  shadow: Color(0xFF000000),
  inverseSurface: Color(0xFF3A302B),
  onInverseSurface: Color(0xFFF5F0ED),
  inversePrimary: Color(0xFFFFB5A0),
);

final themeData = ThemeData(
  colorScheme: colorScheme,
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 57,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 45,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 36,
    ),
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 32, fontWeight: FontWeight.w700, height: 1.25,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 28, fontWeight: FontWeight.w700, height: 1.28,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 24, fontWeight: FontWeight.w600, height: 1.3,
    ),
  ),
);

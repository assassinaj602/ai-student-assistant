import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Primary color swatch for the app theme
const MaterialColor primarySwatch = MaterialColor(0xFF0B3D91, <int, Color>{
  50: Color(0xFFE8EFFB),
  100: Color(0xFFC7D8F6),
  200: Color(0xFFA1BFF0),
  300: Color(0xFF7BA6EA),
  400: Color(0xFF568EE5),
  500: Color(0xFF2F75DF),
  600: Color(0xFF255EBA),
  700: Color(0xFF1B4895),
  800: Color(0xFF12306F),
  900: Color(0xFF08194A),
});

/// Main theme configuration for the AI Student Assistant app
final ThemeData appTheme = ThemeData(
  primarySwatch: primarySwatch,
  colorScheme: ColorScheme.fromSwatch(primarySwatch: primarySwatch).copyWith(
    secondary: Color(0xFF2AB7A9),
    background: Color(0xFFF6F8FA),
    error: Color(0xFFD32F2F),
    onPrimary: Colors.white,
    onSurface: Color(0xFF0F172A),
  ),
  textTheme: GoogleFonts.interTextTheme(),

  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: primarySwatch[700],
    foregroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  // Elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primarySwatch[600],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),

  // Input decoration theme
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primarySwatch[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primarySwatch[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primarySwatch[600]!, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD32F2F)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  // Card theme
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  // FloatingActionButton theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF2AB7A9),
    foregroundColor: Colors.white,
  ),
);

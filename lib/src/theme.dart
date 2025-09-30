import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern green/teal primary color swatch inspired by healthcare/wellness apps
const MaterialColor primarySwatch = MaterialColor(0xFF065F46, <int, Color>{
  50: Color(0xFFECFDF5),
  100: Color(0xFFD1FAE5),
  200: Color(0xFFA7F3D0),
  300: Color(0xFF6EE7B7),
  400: Color(0xFF34D399),
  500: Color(0xFF10B981),
  600: Color(0xFF059669),
  700: Color(0xFF047857),
  800: Color(0xFF065F46),
  900: Color(0xFF064E3B),
});

/// Secondary teal colors
const MaterialColor secondarySwatch = MaterialColor(0xFF0F766E, <int, Color>{
  50: Color(0xFFF0FDFA),
  100: Color(0xFFCCFBF1),
  200: Color(0xFF99F6E4),
  300: Color(0xFF5EEAD4),
  400: Color(0xFF2DD4BF),
  500: Color(0xFF14B8A6),
  600: Color(0xFF0D9488),
  700: Color(0xFF0F766E),
  800: Color(0xFF115E59),
  900: Color(0xFF134E4A),
});

/// Main theme configuration for the AI Student Assistant app
final ThemeData appTheme = ThemeData(
  primarySwatch: primarySwatch,
  colorScheme: ColorScheme.fromSwatch(primarySwatch: primarySwatch).copyWith(
    secondary: secondarySwatch[600]!,
    surface: const Color(0xFFF8FAFC),
    background: const Color(0xFFF1F5F9),
    error: const Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF1E293B),
    onBackground: const Color(0xFF334155),
    primaryContainer: primarySwatch[50],
    secondaryContainer: secondarySwatch[50],
  ),
  textTheme: GoogleFonts.interTextTheme(),

  // AppBar theme - Modern gradient style
  appBarTheme: AppBarTheme(
    backgroundColor: primarySwatch[700],
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    toolbarTextStyle: GoogleFonts.inter(color: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
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
    backgroundColor: secondarySwatch[500],
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Bottom Navigation Bar theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primarySwatch[600],
    unselectedItemColor: const Color(0xFF64748B),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    showUnselectedLabels: true,
    selectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
);

import 'package:flutter/material.dart';

/// Purple gradient primary colors inspired by modern UI
const MaterialColor primarySwatch = MaterialColor(0xFF8B5CF6, <int, Color>{
  50: Color(0xFFF5F3FF),
  100: Color(0xFFEDE9FE),
  200: Color(0xFFDDD6FE),
  300: Color(0xFFC4B5FD),
  400: Color(0xFFA78BFA),
  500: Color(0xFF8B5CF6),
  600: Color(0xFF7C3AED),
  700: Color(0xFF6D28D9),
  800: Color(0xFF5B21B6),
  900: Color(0xFF4C1D95),
});

/// Pink accent colors for gradients and highlights
const MaterialColor secondarySwatch = MaterialColor(0xFFEC4899, <int, Color>{
  50: Color(0xFFFDF2F8),
  100: Color(0xFFFCE7F3),
  200: Color(0xFFFBCFE8),
  300: Color(0xFFF9A8D4),
  400: Color(0xFFF472B6),
  500: Color(0xFFEC4899),
  600: Color(0xFFDB2777),
  700: Color(0xFFBE185D),
  800: Color(0xFF9D174D),
  900: Color(0xFF831843),
});

/// Main theme configuration with dark purple gradient theme
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: primarySwatch,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: primarySwatch,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: secondarySwatch[400]!,
    surface: const Color(0xFF1A1625), // Dark purple surface
    background: const Color(0xFF0F0D1B), // Very dark purple background
    error: const Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white, // White text on dark surfaces
    onBackground: const Color(0xFFE2E8F0), // Light text on dark background
    primaryContainer: primarySwatch[800], // Dark purple containers
    secondaryContainer: const Color(0xFF2D1B3D), // Dark purple containers
    // Gradient-friendly colors
    surfaceVariant: const Color(0xFF252033),
    onSurfaceVariant: const Color(0xFFB8BCC8),
    outline: const Color(0xFF3D3A4B),
    tertiary: secondarySwatch[300]!, // Pink accent
    onTertiary: Colors.white,
  ),
  textTheme: ThemeData.dark().textTheme.copyWith(
    // Ensure all text is white by default
    displayLarge: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    displayMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    displaySmall: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    headlineLarge: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    headlineMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    headlineSmall: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    titleLarge: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    titleMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    titleSmall: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    bodyLarge: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    bodyMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    bodySmall: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    labelLarge: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    labelMedium: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
    labelSmall: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
  ),

  // Scaffold theme - Fix white background issue
  scaffoldBackgroundColor: const Color(0xFF0F0D1B), // Dark purple background
  canvasColor: const Color(0xFF0F0D1B), // Fix white bar under navigation
  // Text selection theme - Fix cursor and text selection colors
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: primarySwatch[400],
    selectionColor: primarySwatch[400]!.withOpacity(0.3),
    selectionHandleColor: primarySwatch[400],
  ),

  // AppBar theme - Purple gradient style
  appBarTheme: AppBarTheme(
    backgroundColor: primarySwatch[700],
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Roboto',
    ),
    toolbarTextStyle: const TextStyle(
      color: Colors.white,
      fontFamily: 'Roboto',
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
  ),

  // Elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primarySwatch[600],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
    ),
  ),

  // Input decoration theme - Dark theme with WHITE text
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252033), // Dark purple input background
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), // Light gray hint
    labelStyle: const TextStyle(color: Colors.white), // WHITE label
    // Force text color to be white
    helperStyle: const TextStyle(color: Colors.white),
    counterStyle: const TextStyle(color: Colors.white),
    errorStyle: const TextStyle(color: Color(0xFFEF4444)),
    prefixStyle: const TextStyle(color: Colors.white),
    suffixStyle: const TextStyle(color: Colors.white),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3D3A4B)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3D3A4B)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primarySwatch[400]!, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
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

  // Bottom Navigation Bar theme - BRIGHT visible icons
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF1A1625), // Dark purple background
    selectedItemColor: const Color(0xFFA78BFA), // BRIGHT purple
    unselectedItemColor: const Color(0xFFD1D5DB), // BRIGHT gray
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    showUnselectedLabels: true,
    selectedIconTheme: const IconThemeData(size: 28, color: Color(0xFFA78BFA)),
    unselectedIconTheme: const IconThemeData(
      size: 24,
      color: Color(0xFFD1D5DB), // Much brighter
    ),
    selectedLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFFA78BFA),
      fontFamily: 'Roboto',
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFFD1D5DB),
      fontFamily: 'Roboto',
    ),
  ),
);

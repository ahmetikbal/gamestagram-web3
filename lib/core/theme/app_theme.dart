import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme configuration for the app
/// Pre-built themes to prevent rebuilding on every widget build
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  /// Pre-built dark theme - created once and reused
  static late final ThemeData _darkTheme;
  
  /// Initialize the theme (call once at app startup)
  static void initialize() {
    _darkTheme = _buildDarkTheme();
  }
  
  /// Get the dark theme
  static ThemeData get darkTheme => _darkTheme;
  
  /// Build the dark theme configuration
  static ThemeData _buildDarkTheme() {
    final baseDarkTheme = ThemeData.dark();
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[900], // A deep charcoal
      scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark theme background
      colorScheme: ColorScheme.dark(
        primary: Colors.tealAccent[400]!, // Vibrant accent for primary actions
        secondary: Colors.pinkAccent[200]!, // Another vibrant accent (optional use)
        surface: Colors.grey[850]!, // For surfaces like cards, dialogs (slightly lighter than scaffold)
        error: Colors.redAccent[400]!,
        onPrimary: Colors.black, // Text/icon color on primary accent
        onSecondary: Colors.black, // Text/icon color on secondary accent
        onSurface: Colors.white, // Text/icon color on surfaces
        onError: Colors.black, // Text/icon color on error
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900]?.withValues(alpha: 0.85), // Slightly transparent AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.tealAccent[400]),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.tealAccent[400], // Default button color
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent[400],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.tealAccent[400],
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.tealAccent[400]!, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey[850], // Matches surface color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme).copyWith(
        bodyLarge: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        titleLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        labelLarge: GoogleFonts.poppins(
          color: Colors.tealAccent[400],
          fontWeight: FontWeight.w600,
        ), // For button text if not overridden by button themes
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF0F5132); // Emerald Deep Forest
  static const Color goldAccent = Color(
    0xFFFFD700,
  ); // Premium Gold for Dark Mode
  static const Color lightGoldAccent = Color(
    0xFFD97706,
  ); // Warm Amber Gold for Light Mode (higher contrast)
  static const Color secondaryGreen = Color(0xFF16A34A); // Vibrant Grass Green

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCardBg = Color(0xFF1E293B); // Slate 800
  static const Color darkGlassBg = Color(
    0x1F334155,
  ); // Slate 700 with transparency
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // Light Mode Colors (Modernized Slate & Emerald)
  static const Color lightBg = Color(
    0xFFF1F5F9,
  ); // Slate 100 - Clean, soft gray-blue
  static const Color lightCardBg = Color(0xFFFFFFFF); // Pure White
  static const Color lightGlassBg = Color(0xC0FFFFFF); // Frosted White Glass
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightBorder = Color(
    0xFFE2E8F0,
  ); // Slate 200 - Very thin divider

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCardBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: Colors.white,
        surface: darkCardBg,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        outline: darkBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            color: darkTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: darkTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: darkTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: darkTextSecondary, fontSize: 14),
          bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
        ),
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
    );
  }

  // Light Theme (Modernized for premium contrast and elegance)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCardBg,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: lightCardBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        outline: lightBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            color: lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: lightTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: lightTextSecondary, fontSize: 14),
          bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12),
        ),
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
    );
  }

  // Glassmorphic Decoration Utility
  static BoxDecoration glassBoxDecoration({
    required BuildContext context,
    double borderRadius = 16,
    double borderWidth = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkGlassBg : lightGlassBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? darkBorder : lightBorder).withOpacity(0.7),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.blueGrey.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

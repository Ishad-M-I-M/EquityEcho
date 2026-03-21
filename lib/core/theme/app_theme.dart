import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ──────────────────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _primaryMid = Color(0xFF1B2838);
  static const Color _surfaceDark = Color(0xFF152232);
  static const Color _cardDark = Color(0xFF1E3044);
  static const Color _accent = Color(0xFF00E5A0);
  static const Color _accentLight = Color(0xFF4DFFC3);
  static const Color _sellRed = Color(0xFFFF6B6B);
  static const Color _buyGreen = Color(0xFF00E5A0);
  static const Color _fundBlue = Color(0xFF5CB8FF);
  static const Color _textPrimary = Color(0xFFF0F4F8);
  static const Color _textSecondary = Color(0xFF8DA4BF);
  static const Color _divider = Color(0xFF2A3F55);
  static const Color _warning = Color(0xFFFFB84D);

  // Public accessors
  static Color get accent => _accent;
  static Color get accentLight => _accentLight;
  static Color get sellRed => _sellRed;
  static Color get buyGreen => _buyGreen;
  static Color get fundBlue => _fundBlue;
  static Color get textSecondary => _textSecondary;
  static Color get cardDark => _cardDark;
  static Color get warning => _warning;
  static Color get surfaceDark => _surfaceDark;
  static Color get divider => _divider;

  // ─── Theme Data ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _primaryDark,
      textTheme: textTheme.apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _accentLight,
        surface: _surfaceDark,
        error: _sellRed,
        onPrimary: _primaryDark,
        onSecondary: _primaryDark,
        onSurface: _textPrimary,
        onError: _textPrimary,
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _primaryMid,
        indicatorColor: _accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent);
          }
          return const IconThemeData(color: _textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: _textSecondary,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: _textSecondary),
        labelStyle: GoogleFonts.inter(color: _textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: _primaryDark,
      ),
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark,
        contentTextStyle: GoogleFonts.inter(color: _textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceDark,
        selectedColor: _accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 13),
        side: const BorderSide(color: _divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

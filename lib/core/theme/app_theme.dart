import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette (Dark) ───────────────────────────────────────────────────
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _primaryMidDark = Color(0xFF1B2838);
  static const Color _surfaceDark = Color(0xFF152232);
  static const Color _cardDark = Color(0xFF1E3044);
  static const Color _textPrimaryDark = Color(0xFFF0F4F8);
  static const Color _textSecondaryDark = Color(0xFF8DA4BF);
  static const Color _dividerDark = Color(0xFF2A3F55);

  // ─── Color Palette (Light) ──────────────────────────────────────────────────
  static const Color _primaryLight = Color(0xFFF8FAFC);
  static const Color _primaryMidLight = Color(0xFFE2E8F0);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textPrimaryLight = Color(0xFF0D1B2A);
  static const Color _textSecondaryLight = Color(0xFF475569);
  static const Color _dividerLight = Color(0xFFCBD5E1);

  // ─── Shared Colors ──────────────────────────────────────────────────────────
  static const Color _accent = Color(0xFF00E5A0);
  static const Color _accentLight = Color(0xFF4DFFC3);
  static const Color _sellRed = Color(0xFFFF6B6B);
  static const Color _buyGreen = Color(0xFF00E5A0);
  static const Color _fundBlue = Color(0xFF5CB8FF);
  static const Color _warning = Color(0xFFFFB84D);

  // Public accessors for shared colors
  static Color get accent => _accent;
  static Color get accentLight => _accentLight;
  static Color get sellRed => _sellRed;
  static Color get buyGreen => _buyGreen;
  static Color get fundBlue => _fundBlue;
  static Color get warning => _warning;

  // ─── Theme Data (Dark) ──────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _primaryDark,
      textTheme: textTheme.apply(
        bodyColor: _textPrimaryDark,
        displayColor: _textPrimaryDark,
      ),
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _accentLight,
        surface: _surfaceDark,
        error: _sellRed,
        onPrimary: _primaryDark,
        onSecondary: _primaryDark,
        onSurface: _textPrimaryDark,
        onError: _textPrimaryDark,
        onSurfaceVariant: _textSecondaryDark,
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardColor: _cardDark,
      dividerColor: _dividerDark,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: _textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: _textPrimaryDark),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _primaryMidDark,
        indicatorColor: _accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent);
          }
          return const IconThemeData(color: _textSecondaryDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(color: _textSecondaryDark, fontSize: 12);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: _textSecondaryDark),
        labelStyle: GoogleFonts.inter(color: _textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: _primaryDark,
      ),
      dividerTheme: const DividerThemeData(color: _dividerDark, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark,
        contentTextStyle: GoogleFonts.inter(color: _textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceDark,
        selectedColor: _accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: _textPrimaryDark, fontSize: 13),
        side: const BorderSide(color: _dividerDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── Theme Data (Light) ─────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _primaryLight,
      textTheme: textTheme.apply(
        bodyColor: _textPrimaryLight,
        displayColor: _textPrimaryLight,
      ),
      colorScheme: const ColorScheme.light(
        primary: _accent,
        secondary: _accentLight,
        surface: _surfaceLight,
        error: _sellRed,
        onPrimary: _primaryLight,
        onSecondary: _primaryLight,
        onSurface: _textPrimaryLight,
        onError: _textPrimaryLight,
        onSurfaceVariant: _textSecondaryLight,
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 1,
        shadowColor: _primaryMidLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _dividerLight, width: 0.5),
        ),
      ),
      cardColor: _cardLight,
      dividerColor: _dividerLight,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: _textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: _textPrimaryLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceLight,
        indicatorColor: _accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent);
          }
          return const IconThemeData(color: _textSecondaryLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(color: _textSecondaryLight, fontSize: 12);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: _textSecondaryLight),
        labelStyle: GoogleFonts.inter(color: _textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: _primaryLight,
      ),
      dividerTheme: const DividerThemeData(color: _dividerLight, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark, // Keep snackbar dark for contrast even in light theme
        contentTextStyle: GoogleFonts.inter(color: _textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceLight,
        selectedColor: _accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: _textPrimaryLight, fontSize: 13),
        side: const BorderSide(color: _dividerLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

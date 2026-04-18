import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color bg = Color(0xFF0C1017);
  static const Color surface = Color(0xFF12161F);
  static const Color surfaceHi = Color(0xFF1A1F2E);
  static const Color border = Color(0xFF252B3B);
  static const Color muted = Color(0xFF5C6478);
  static const Color text = Color(0xFFE1E4ED);
  static const Color accent = Color(0xFF38BDF8);
  static const Color accent2 = Color(0xFFA78BFA);
  static const Color accent3 = Color(0xFF34D399);
  static const Color gold = Color(0xFFFBBF24);
  static const Color red = Color(0xFFF87171);
  static const Color green = Color(0xFF4ADE80);

  static const List<Color> slotColors = [accent, accent2, accent3];

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: gold,
        error: red,
        onSurface: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _heading(18, text),
        iconTheme: const IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: _body(15, muted),
        hintStyle: _body(15, muted),
        // Taller touch target for mobile
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: _heading(15, bg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      textTheme: TextTheme(
        headlineLarge: _heading(28, text),
        headlineMedium: _heading(24, text),
        headlineSmall: _heading(20, text),
        titleLarge: _heading(18, text),
        titleMedium: _heading(16, text),
        titleSmall: _heading(14, text),
        bodyLarge: _body(16, text),
        bodyMedium: _body(14, text),
        bodySmall: _body(12, muted),
        labelLarge: _label(14, text),
        labelMedium: _label(12, text),
        labelSmall: _label(11, muted),
      ),
    );
  }

  static TextStyle _heading(double size, Color color) => GoogleFonts.outfit(
      fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle _body(double size, Color color) => GoogleFonts.inter(
      fontSize: size, fontWeight: FontWeight.w400, color: color);

  static TextStyle _label(double size, Color color) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle mono(double size, {Color color = text}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, color: color, fontWeight: FontWeight.w400);
}

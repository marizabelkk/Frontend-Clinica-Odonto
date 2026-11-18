import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Identidade institucional: azul marinho, azul royal e amarelo ouro.
  static const Color navy = Color(0xFF082B5C);
  static const Color royalBlue = Color(0xFF073E87);
  static const Color gold = Color(0xFFFFC900);
  static const Color lightText = Color(0xFF102B53);
  static const Color darkBackground = Color(0xFF071426);
  static const Color darkSurface = Color(0xFF101E32);
  static const Color darkText = Color(0xFFF4F7FC);

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    primary: navy,
    surface: Colors.white,
    foreground: lightText,
    border: const Color(0xFFDCE3ED),
    scaffold: Colors.transparent,
    field: Colors.white.withValues(alpha: 0.94),
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF8DBBFF),
    surface: darkSurface,
    foreground: darkText,
    border: const Color(0xFF34445C),
    scaffold: Colors.transparent,
    field: const Color(0xFF15243A),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color surface,
    required Color foreground,
    required Color border,
    required Color scaffold,
    required Color field,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: royalBlue,
      brightness: brightness,
      primary: primary,
      secondary: gold,
      surface: surface,
      onSurface: foreground,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: 0.94),
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: foreground),
        bodyMedium: TextStyle(color: foreground),
        titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(color: foreground.withValues(alpha: 0.62)),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

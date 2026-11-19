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
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: border),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final actionColor = brightness == Brightness.dark ? gold : primary;
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
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: brightness == Brightness.dark ? 0 : 8,
        shape: dialogShape,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: foreground, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: brightness == Brightness.dark ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: border),
        ),
        showDragHandle: true,
        dragHandleColor: border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: TextStyle(color: foreground.withValues(alpha: 0.62)),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD92332)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD92332), width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: actionColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark ? navy : Colors.white,
          minimumSize: const Size(48, 44),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionColor,
          side: BorderSide(color: border),
          minimumSize: const Size(48, 44),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark ? navy : Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

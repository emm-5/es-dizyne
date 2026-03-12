import 'package:flutter/material.dart';

class ESDizyneTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color accent = Color(0xFFFF6584);
  static const Color accentGold = Color(0xFFFFD700);

  // Dark Theme (Default)
  static const Color darkBg = Color(0xFF0F0F13);
  static const Color darkSurface = Color(0xFF1A1A24);
  static const Color darkCard = Color(0xFF22222F);
  static const Color darkBorder = Color(0xFF2E2E3F);
  static const Color darkHover = Color(0xFF2A2A3A);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6B6B85);

  // Tool Colors
  static const Color toolActive = Color(0xFF6C63FF);
  static const Color toolInactive = Color(0xFF3A3A4F);
  static const Color canvasBg = Color(0xFF2A2A35);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkSurface,
      background: darkBg,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
    ),
    cardTheme: CardTheme(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    iconTheme: const IconThemeData(color: textSecondary, size: 22),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textMuted),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primary,
      thumbColor: primary,
      inactiveTrackColor: darkBorder,
      overlayColor: Color(0x336C63FF),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected) ? primary : textMuted,
      ),
      trackColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? primary.withOpacity(0.5)
            : darkBorder,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: darkBorder),
      ),
      textStyle: const TextStyle(color: textPrimary, fontSize: 12),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5FA),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: Colors.white,
      background: Color(0xFFF5F5FA),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
    ),
  );
}

// Gradient presets
class ESDizyneGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF0F0F13)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient toolbarGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF22222F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

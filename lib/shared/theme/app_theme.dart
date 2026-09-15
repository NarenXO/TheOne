import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color accent = Color(0xFF03DAC6);

  // Status & Evidence Colors
  static const Color verifiedGreen = Color(0xFF1B5E20);
  static const Color uncertainAmber = Color(0xFFE65100);
  static const Color insufficientGrey = Color(0xFF424242);
  static const Color conflictRed = Color(0xFFB71C1C);

  // Sensor Indicators
  static const Color sensorActive = Color(0xFFD32F2F);
  static const Color sensorInactive = Color(0xFF388E3C);

  // Emergency / SOS
  static const Color sosRed = Color(0xFFC62828);
}

class AppTheme {
  static ThemeData light({double textScale = 1.0, bool highContrast = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: highContrast ? Colors.black : AppColors.primary,
        surface: highContrast ? Colors.white : const Color(0xFFF8F9FA),
        error: AppColors.conflictRed,
      ),
      scaffoldBackgroundColor: highContrast ? Colors.white : const Color(0xFFF5F5F7),
      cardTheme: CardThemeData(
        elevation: highContrast ? 4 : 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 18 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: _buildTextTheme(Brightness.light, textScale, highContrast),
    );
  }

  static ThemeData dark({double textScale = 1.0, bool highContrast = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: highContrast ? Colors.white : const Color(0xFFBB86FC),
        surface: highContrast ? Colors.black : const Color(0xFF1E1E1E),
        error: AppColors.conflictRed,
      ),
      scaffoldBackgroundColor: highContrast ? Colors.black : const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: highContrast ? 4 : 2,
        color: highContrast ? const Color(0xFF1A1A1A) : const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 18 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: _buildTextTheme(Brightness.dark, textScale, highContrast),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness, double scale, bool hc) {
    final baseColor = brightness == Brightness.light
        ? (hc ? Colors.black : const Color(0xFF1C1B1F))
        : (hc ? Colors.white : const Color(0xFFE6E1E5));

    return TextTheme(
      headlineLarge: TextStyle(fontSize: 32 * scale, fontWeight: FontWeight.bold, color: baseColor),
      headlineMedium: TextStyle(fontSize: 26 * scale, fontWeight: FontWeight.bold, color: baseColor),
      headlineSmall: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w700, color: baseColor),
      titleLarge: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w600, color: baseColor),
      titleMedium: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: baseColor),
      bodyLarge: TextStyle(fontSize: 18 * scale, color: baseColor),
      bodyMedium: TextStyle(fontSize: 16 * scale, color: baseColor),
      labelLarge: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold, color: baseColor),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF02060E);
  static const Color surface = Color(0xFF10051B);
  static const Color card = Color(0xE61A0829);
  static const Color field = Color(0xCC090311);
  static const Color primary = Color(0xFFB20BE8);
  static const Color secondary = Color(0xFF9303C5);
  static const Color accent = Color(0xFFD85BFF);
  static const Color text = Color(0xFFF8EEFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF02060E), Color(0xFF21052F), Color(0xFF9303C5)],
    stops: [0.08, 0.58, 1],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9303C5), Color(0xFFCB19FF)],
  );

  static const Color success = Color(0xFF22C55E);

  static const Color warning = Color(0xFFF59E0B);

  static const Color danger = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: Colors.transparent,

    fontFamily: "Inter",

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    ),

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
    ),
  );
}

class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}

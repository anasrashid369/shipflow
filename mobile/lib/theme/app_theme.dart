import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF08080B);
  static const surface = Color(0xFF15151A);
  static const surfaceElevated = Color(0xFF1E1E25);
  static const border = Color(0xFF2A2A33);

  // Duotone core
  static const emerald = Color(0xFF10D9A3);
  static const emeraldDim = Color(0xFF0BA37A);
  static const violet = Color(0xFF8B5CF6);
  static const violetDim = Color(0xFF6D28D9);

  static const textPrimary = Color(0xFFF7F7F8);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textTertiary = Color(0xFF6B6B75);

  static const critical = Color(0xFFFF5A6E);
  static const warning = Color(0xFFFFA53E);
  static const info = violet;

  static const duotoneGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, violet],
  );

  static const emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, emeraldDim],
  );

  static const violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, violetDim],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.emerald,
      secondary: AppColors.violet,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}
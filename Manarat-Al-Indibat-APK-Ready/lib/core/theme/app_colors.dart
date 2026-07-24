import 'package:flutter/material.dart';

/// Cyberpunk / glassmorphism dark palette.
/// Neon accents on deep space backgrounds, matching the visual language
/// of the existing HTML build of منارة الانضباط.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF06070C);
  static const Color surface = Color(0xFF0D0F1A);
  static const Color surfaceElevated = Color(0xFF13172A);
  static const Color glassFill = Color(0x1AFFFFFF); // white @ 10%
  static const Color glassBorder = Color(0x33FFFFFF); // white @ 20%

  // Neon accents
  static const Color primary = Color(0xFF00E5FF); // cyan
  static const Color secondary = Color(0xFF7C4DFF); // violet
  static const Color tertiary = Color(0xFFFF2EC4); // magenta

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC400);
  static const Color danger = Color(0xFFFF3D57);

  // Text
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFFA3A8C3);
  static const Color textMuted = Color(0xFF5E6382);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF06070C), Color(0xFF0B0E1F), Color(0xFF120A22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [tertiary, danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

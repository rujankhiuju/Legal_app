import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // New design system (dark navy + gold)
  static const primaryBg = Color(0xFF0A192F);
  static const surface = Color(0xFF112240);
  static const accentPrimary = Color(0xFFD4AF37);
  static const accentSecondary = Color(0xFFCCD6F6);
  static const textPrimary = Color(0xFFE6F1FF);
  static const textSecondary = Color(0xFF8892B0);
  static const divider = Color(0x14FFFFFF);

  // Legacy light mode colors (used by existing screens)
  static const lightBackground = Color(0xFFF5F3F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF2C2C2C);
  static const lightSecondary = Color(0xFF8B7E6B);
  static const lightAccent = Color(0xFFC4A882);
  static const lightText = Color(0xFF1C1C1E);
  static const lightSubtitle = Color(0xFF8E8E93);
  static const lightDivider = Color(0xFFE5E0DB);

  // Legacy dark mode colors (used by existing screens)
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkSecondary = Color(0xFFAEAEB2);
  static const darkAccent = Color(0xFFD4D4D4);
  static const darkText = Color(0xFFFFFFFF);
  static const darkSubtitle = Color(0xFF8E8E93);
  static const darkDivider = Color(0xFF38383A);

  // Legacy accent / semantic colors (used by existing screens)
  static const gold = Color(0xFFC4A882);
  static const goldLight = Color(0xFFD4C4A8);
  static const deepNavy = Color(0xFF1C1C1E);
  static const darkBlue = Color(0xFF2C2C2C);

  // Semantic colors (shared by new and legacy)
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF64FFDA);
  static const warning = Color(0xFFFF9500);

  // Utility
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

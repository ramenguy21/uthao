import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Surface hierarchy — depth through tonal shift, no shadows
  static const Color background = Color(0xFF0E0E0E); // Level 0 — the void
  static const Color surface = Color(0xFF131313);    // Level 1
  static const Color card = Color(0xFF201F1F);        // Level 2 — cards
  static const Color cardHigh = Color(0xFF2A2A2A);   // Level 3 — inputs, active rows

  // The single accent — blood red, surgical use only
  static const Color accent = Color(0xFFC0392B);
  static const Color accentBright = Color(0xFFE74C3C); // hover/pressed state

  // Text hierarchy
  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF5C5C5C);

  // Ghost border — used only when tonal shift can't provide separation
  static const Color ghostBorder = Color(0xFF2A2A2A);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Space Grotesk — display numbers, day names, big readouts ──

  /// App wordmark — "uthao"
  static TextStyle get appTitle => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: AppColors.white,
      );

  /// Large numeric display — weight lifted, rep count, timers
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.0,
      );

  /// Medium numeric display
  static TextStyle get displayMd => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.0,
      );

  /// Card/section header — workout day name
  static TextStyle get headingLg => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.white,
      );

  static TextStyle get headingMd => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  // ── Inter — body text, labels, metadata ──

  /// Screen section label — "SELECT WORKOUT"
  static TextStyle get screenLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: AppColors.textMuted,
      );

  /// Exercise names, data rows
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Metadata chips, unit labels
  static TextStyle get meta => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: AppColors.textMuted,
      );

  /// Button labels — uppercase, tracked
  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.white,
      );

  /// Set number column — monospaced feel
  static TextStyle get setNumber => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}

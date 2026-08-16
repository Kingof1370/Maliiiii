import 'package:flutter/material.dart';

/// پالت رنگی محصول در دو حالت روشن و تاریک.
///
/// رنگ‌ها بر اساس روان‌شناسی مالی انتخاب شده‌اند:
/// سبز = وضعیت مثبت، قرمز = خطر، نارنجی = هشدار، طلایی = هدف/حق بیمه،
/// آبی = اطلاعات. از استفادهٔ افراطی از رنگ پرهیز شده است.
final class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.positive,
    required this.danger,
    required this.warning,
    required this.gold,
    required this.goldSoft,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.cardGlow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color positive;
  final Color danger;
  final Color warning;
  final Color gold;
  final Color goldSoft;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color cardGlow;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDF0F7),
    surfaceElevated: Color(0xFFFBFCFE),
    primary: Color(0xFF3B5BDB),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE8EDFC),
    positive: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
    warning: Color(0xFFDF8500),
    gold: Color(0xFF9C7A1C),
    goldSoft: Color(0xFFF7EFD8),
    info: Color(0xFF2563EB),
    textPrimary: Color(0xFF10192C),
    textSecondary: Color(0xFF56617A),
    textMuted: Color(0xFF8A94A9),
    divider: Color(0xFFE4E8F1),
    cardGlow: Color(0xFFB9C6F0),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0E18),
    surface: Color(0xFF121A2B),
    surfaceMuted: Color(0xFF1A2438),
    surfaceElevated: Color(0xFF1E2A42),
    primary: Color(0xFF7C93F5),
    onPrimary: Color(0xFF0B1226),
    primarySoft: Color(0xFF222F4F),
    positive: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    gold: Color(0xFFE3C25C),
    goldSoft: Color(0xFF3A3320),
    info: Color(0xFF60A5FA),
    textPrimary: Color(0xFFEAF0FC),
    textSecondary: Color(0xFF9AA6C0),
    textMuted: Color(0xFF68738F),
    divider: Color(0xFF232E45),
    cardGlow: Color(0xFF2C3B63),
  );
}

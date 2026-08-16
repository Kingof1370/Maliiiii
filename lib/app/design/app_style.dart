import 'package:flutter/material.dart';

import 'app_colors.dart';

/// سایه‌های لایه‌ای و گرادیان‌های استاندارد سیستم طراحی سه‌بعدی.
abstract final class AppStyle {
  /// سه لایهٔ سایه برای حس عمق: سایهٔ نزدیک، سایهٔ دور و درخشش رنگی ملایم.
  static List<BoxShadow> shadows(
    AppPalette palette, {
    double depth = 1,
    Color? tint,
  }) {
    final Color glow = tint ?? palette.cardGlow;
    return <BoxShadow>[
      BoxShadow(
        color: palette.textPrimary.withValues(alpha: 0.07 * depth),
        offset: Offset(0, 2 * depth),
        blurRadius: 6 * depth,
      ),
      BoxShadow(
        color: palette.textPrimary.withValues(alpha: 0.05 * depth),
        offset: Offset(0, 10 * depth),
        blurRadius: 24 * depth,
      ),
      BoxShadow(
        color: glow.withValues(alpha: 0.10 * depth),
        offset: Offset.zero,
        blurRadius: 32 * depth,
      ),
    ];
  }

  /// سطح کارت: از رنگ روشن در بالا تا سطح اصلی در پایین.
  static LinearGradient surfaceGradient(AppPalette palette) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[palette.surfaceElevated, palette.surface],
      );

  /// گرادیان محو برای انتهای لیست‌ها.
  static LinearGradient scrimGradient(AppPalette palette) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          palette.background,
          palette.background.withValues(alpha: 0),
        ],
      );
}

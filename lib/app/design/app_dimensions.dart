import 'package:flutter/material.dart';

/// مقیاس فاصله، گوشه‌ها و مدت‌زمان حرکت رابط کاربری.
abstract final class AppDimensions {
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 999;

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionMedium = Duration(milliseconds: 300);
  static const Duration motionSlow = Duration(milliseconds: 520);

  /// اگر کاربر «حرکت کاهش‌یافته» سیستم را فعال کرده باشد، انیمیشن حذف می‌شود.
  static bool motionEnabled(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);
}

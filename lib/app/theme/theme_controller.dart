import 'package:flutter/material.dart';

/// کنترل‌کنندهٔ تم که در فاز «پروفایل و تنظیمات» پایدار (persist) می‌شود.
/// در این فاز فقط حالت حافظه‌ای را نگه می‌دارد تا UI از ThemeMode استفاده کند.
class ThemeController {
  ThemeMode mode = ThemeMode.system;
}

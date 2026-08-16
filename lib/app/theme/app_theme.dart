import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';

/// دسترسی راحت به پالت محصول از درون هر ویجت.
extension AppPaletteContext on BuildContext {
  AppPalette get appPalette => Theme.of(this).extension<AppColorsExtension>()!.palette;
}

/// رنگ‌های سفارشی محصول که داخل ThemeData جاسازی می‌شوند.
final class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({required this.palette});

  final AppPalette palette;

  @override
  AppColorsExtension copyWith({AppPalette? palette}) =>
      AppColorsExtension(palette: palette ?? this.palette);

  @override
  AppColorsExtension lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(palette: t < 0.5 ? palette : other.palette);
  }
}

/// ساخت ThemeData کامل برای حالت روشن یا تاریک.
ThemeData buildAppTheme(Brightness brightness) {
  final AppPalette palette =
      brightness == Brightness.light ? AppPalette.light : AppPalette.dark;

  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    secondary: palette.primarySoft,
    onSecondary: palette.textPrimary,
    error: palette.danger,
    onError: Colors.white,
    surface: palette.surface,
    onSurface: palette.textPrimary,
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: palette.background,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppColorsExtension(palette: palette),
    ],
    textTheme: base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
      fontFamily: 'Vazirmatn',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: palette.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            brightness == Brightness.light ? Brightness.light : Brightness.dark,
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.divider, space: 1),
    iconTheme: IconThemeData(color: palette.textSecondary),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.surfaceElevated,
      contentTextStyle: TextStyle(
        color: palette.textPrimary,
        fontFamily: 'Vazirmatn',
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    ),
  );
}

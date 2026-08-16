import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../design/app_style.dart';
import '../theme/app_theme.dart';

/// سطح «ارتفاع» کارت که شدت سایه و عمق را تعیین می‌کند.
enum PremiumElevation { flat, raised, floating, overlay }

/// کارت لایه‌ای سه‌بعدی با سایهٔ نرم، گرادیان سطح و حالت شیشه‌ای.
///
/// 3D در اینجا کاربردی است: عمق قابل‌درک برای سلسله‌مراتب اطلاعات،
/// بدون سنگین‌کردن رندر. اگر سیستم «حرکت کاهش‌یافته» فعال باشد،
/// میکرو-انیمیشن فشردن به‌طور خودکار حذف می‌شود.
class PremiumCard extends StatefulWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.elevation = PremiumElevation.raised,
    this.radius = AppDimensions.radiusLg,
    this.padding = const EdgeInsets.all(AppDimensions.spaceMd),
    this.gradient,
    this.glass = false,
    this.accent,
    this.onTap,
  });

  final Widget child;
  final PremiumElevation elevation;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final bool glass;

  /// رنگ درخشش (glow) کارت؛ پیش‌فرض از پالت خوانده می‌شود.
  final Color? accent;
  final VoidCallback? onTap;

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  double _press = 1;

  void _pressDown() {
    if (AppDimensions.motionEnabled(context)) {
      setState(() => _press = 0.96);
    }
  }

  void _release() => setState(() => _press = 1);

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final bool motion = AppDimensions.motionEnabled(context);
    final double depth = (widget.elevation.index * 0.6 + 1) * _press;
    final List<BoxShadow> shadows =
        AppStyle.shadows(palette, depth: depth, tint: widget.accent);

    Widget surface = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: widget.gradient ?? AppStyle.surfaceGradient(palette),
        boxShadow: shadows,
        border: widget.glass
            ? Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.65),
              )
            : null,
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.glass) {
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: surface,
        ),
      );
    }

    if (widget.onTap != null) {
      surface = GestureDetector(
        onTapDown: (_) => _pressDown(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: widget.onTap,
        child: surface,
      );
    }

    return AnimatedScale(
      scale: _press,
      duration: motion ? AppDimensions.motionFast : Duration.zero,
      curve: Curves.easeOutCubic,
      child: surface,
    );
  }
}

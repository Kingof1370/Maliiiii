import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../theme/app_theme.dart';

/// پس‌زمینهٔ عمیق با دو درخشش نرم برای حس فضا و عمق در صفحات اصلی.
class PremiumBackdrop extends StatelessWidget {
  const PremiumBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final bool bright = Theme.of(context).brightness == Brightness.light;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.background,
                  bright ? const Color(0xFFEDF1FA) : const Color(0xFF0C1322),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _Glow(radius: 260, color: palette.primarySoft),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _Glow(radius: 300, color: palette.goldSoft),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool bright = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: bright ? 0.55 : 0.35),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

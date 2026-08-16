import 'package:flutter/material.dart';

import '../branding.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../theme/app_theme.dart';

/// امضای ظریف و طلایی توسعه‌دهنده؛ عمداً کوچک و غیرمزاحم است.
class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Padding(
      padding: EdgeInsets.all(
        compact ? AppDimensions.spaceSm : AppDimensions.spaceMd,
      ),
      child: Text(
        '${Branding.developerTitle}: ${Branding.developerName}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.gold,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

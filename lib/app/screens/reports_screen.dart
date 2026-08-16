import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';

/// گزارش‌ها و نمودارهای تعاملی؛ در فاز «گزارش‌ها» داده‌محور می‌شود.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Text(
            'گزارش‌ها',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PremiumCard(
            elevation: PremiumElevation.raised,
            child: Column(
              children: <Widget>[
                Icon(Icons.insights_rounded,
                    size: 52, color: palette.primary),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  'هنوز داده‌ای برای گزارش نیست',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'گزارش متنی، نموداری و پیش‌بینی بعد از ثبت درآمد و هزینه فعال می‌شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

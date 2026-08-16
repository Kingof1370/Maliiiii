import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';

/// مرکز وام‌ها و بدهی‌ها؛ در فاز چند-وام به موتور مالی متصل می‌شود.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Text(
            FaStrings.loans,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PremiumCard(
            elevation: PremiumElevation.raised,
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.request_quote_rounded,
                  size: 52,
                  color: palette.primary,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  FaStrings.noLoanYet,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'در فاز «موتور چند-وام» ثبت وام، اقساط و پرداخت‌ها اضافه می‌شود.',
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

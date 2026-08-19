import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/ledger_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';

/// دستیار هوشمند محلی: بینش‌های مالی تولیدشده از دفترکل، کاملاً درون‌دستگاهی.
///
/// هیچ داده‌ای به بیرون ارسال نمی‌شود؛ موتور [buildInsights] فقط داده‌های
/// محلی را تحلیل می‌کند.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    final bool aiEnabled = ProfileScope.of(context).profile?.aiEnabled ?? false;
    final List<Insight> insights =
        buildInsights(ledger, asOf: DateTime.now());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, color: palette.gold),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'دستیار هوشمند',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            aiEnabled
                ? 'تحلیل محلیِ داده‌های شما — بدون ارسال به بیرون.'
                : 'تحلیل محلی فعال نشده؛ می‌توانی از تنظیمات روشنش کنی.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          if (insights.isEmpty)
            _EmptyAssistant(palette: palette)
          else
            for (final Insight insight in insights)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.spaceMd),
                child: _InsightCard(insight: insight),
              ),
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  (IconData, Color) _visual(AppPalette palette) => switch (insight.tone) {
        InsightTone.good => (Icons.check_circle_rounded, palette.positive),
        InsightTone.warning => (Icons.warning_amber_rounded, palette.warning),
        InsightTone.info => (Icons.info_outline_rounded, palette.info),
        InsightTone.neutral => (Icons.tips_and_updates_rounded, palette.primary),
      };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final (IconData icon, Color color) = _visual(palette);
    return PremiumCard(
      elevation: PremiumElevation.raised,
      accent: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssistant extends StatelessWidget {
  const _EmptyAssistant({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.psychology_alt_outlined,
              size: 52, color: palette.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'هنوز داده‌ای برای تحلیل نیست',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'با ثبت چند تراکنش، بینش‌های مالی اینجا ظاهر می‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

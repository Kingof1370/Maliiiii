import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/ledger_scope.dart';
import '../state/report_data.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import '../widgets/report_charts.dart';

/// گزارش‌های داده‌محور: خلاصهٔ ماه شمسی، سلامت مالی، پیش‌بینی، تفکیک
/// دسته‌ها و گزارش متنی قابل‌کپی.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  JalaliDate _month = JalaliDate.today();

  void _shiftMonth(int delta) => setState(() {
        _month = _month.addMonths(delta);
      });

  @override
  Widget build(BuildContext context) {
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    final JalaliMonthReport report = buildJalaliMonthReport(ledger, _month);
    final DateTime now = DateTime.now();
    final List<CategorySlice> categories = categoryBreakdown(
      ledger,
      report.start,
      report.end,
    );
    final List<TrendPoint> trend = trendSeries(ledger, _month);
    final int health = ledger.healthScore(_month.toGregorian()).value;
    final Forecast? forecast = ledger.forecast(
      asOf: now,
      periodEnd: _month.addMonths(1).toGregorian(),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'گزارش‌ها',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('report-prev-month'),
                tooltip: 'ماه قبل',
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Text(
                '${_month.monthName} ${toPersianDigits(_month.year)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                key: const Key('report-next-month'),
                tooltip: 'ماه بعد',
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (ledger.transactions.isEmpty)
            const _EmptyReport()
          else ...<Widget>[
            _SummaryCard(report: report),
            const SizedBox(height: AppDimensions.spaceMd),
            _HealthCard(score: health, explanation: _healthExplanation(context, health)),
            const SizedBox(height: AppDimensions.spaceMd),
            _ForecastCard(forecast: forecast),
            if (categories.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppDimensions.spaceMd),
              _CategoriesCard(categories: categories),
            ],
            if (trend.any((TrendPoint point) =>
                point.income.minorUnits > 0 || point.expense.minorUnits > 0)) ...<Widget>[
              const SizedBox(height: AppDimensions.spaceMd),
              _TrendCard(points: trend),
            ],
            const SizedBox(height: AppDimensions.spaceMd),
            _TextReportCard(
              text: buildTextReport(
                report: report,
                month: _month,
                healthScore: health,
                categories: categories,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }

  String _healthExplanation(BuildContext context, int score) {
    if (score >= 80) return 'وضعیت مالی عالی است؛ ادامه بده.';
    if (score >= 60) return 'وضعیت خوب است؛ کمی به پس‌انداز توجه کن.';
    if (score >= 40) return 'وضعیت متوسط است؛ هزینه‌ها را مرور کن.';
    return 'وضعیت شکننده است؛ بودجه و بدهی را جدی بگیر.';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final JalaliMonthReport report;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'خلاصهٔ ماه',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              _Metric(
                label: 'درآمد',
                value: formatMinorUnits(report.income.minorUnits),
                color: palette.positive,
              ),
              const Spacer(),
              _Metric(
                label: 'هزینه',
                value: formatMinorUnits(report.expense.minorUnits),
                color: palette.danger,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              _Metric(
                label: 'اقساط',
                value: formatMinorUnits(report.installments.minorUnits),
                color: palette.warning,
              ),
              const Spacer(),
              _Metric(
                label: 'جریان نقدی',
                value: formatMinorUnits(report.cashflow.minorUnits),
                color: report.cashflow.isNegative
                    ? palette.danger
                    : palette.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score, required this.explanation});

  final int score;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final Color color = score >= 60
        ? palette.positive
        : score >= 40
            ? palette.warning
            : palette.danger;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      accent: color,
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                toPersianDigits(score),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'امتیاز سلامت مالی',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  explanation,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
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

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});

  final Forecast? forecast;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      key: const Key('report-forecast-card'),
      elevation: PremiumElevation.raised,
      accent: palette.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_graph_rounded, color: palette.info),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'پیش‌بینی تا پایان ماه',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (forecast == null)
            Text(
              'دادهٔ کافی برای پیش‌بینی نیست؛ چند روز دیگر ثبت کن.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            )
          else ...<Widget>[
            _ForecastRow(
              label: 'درآمد پیش‌بینی‌شده',
              value: formatMinorUnits(forecast!.expectedIncome.minorUnits),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            _ForecastRow(
              label: 'هزینهٔ پیش‌بینی‌شده',
              value: formatMinorUnits(forecast!.expectedExpense.minorUnits),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            _ForecastRow(
              label: 'موجودی پایان ماه',
              value: formatMinorUnits(forecast!.expectedBalance.minorUnits),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              'بر پایهٔ ${toPersianDigits(forecast!.sampleDays)} روز نمونه',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.categories});

  final List<CategorySlice> categories;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final int total =
        categories.fold<int>(0, (sum, item) => sum + item.amount.minorUnits);
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'سهم دسته‌ها از هزینه',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          DonutChart(slices: categories, palette: palette),
          const SizedBox(height: AppDimensions.spaceMd),
          for (final CategorySlice slice in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          slice.category,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        formatMinorUnits(slice.amount.minorUnits),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${toPersianDigits((slice.fraction(total) * 100).round())}٪',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                    child: LinearProgressIndicator(
                      value: slice.fraction(total),
                      minHeight: 6,
                      backgroundColor: palette.primary.withValues(alpha: 0.1),
                      color: palette.primary,
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

class _TextReportCard extends StatelessWidget {
  const _TextReportCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.description_outlined, color: palette.primary),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'گزارش متنی',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: SelectableText(
              text,
              style: TextStyle(
                color: palette.textPrimary,
                height: 1.7,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.insights_rounded, size: 52, color: palette.primary),
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
            'با ثبت درآمد و هزینه، گزارش متنی، نموداری و پیش‌بینی فعال می‌شود.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      key: const Key('report-trend-card'),
      elevation: PremiumElevation.raised,
      accent: palette.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.show_chart_rounded, color: palette.primary),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'روند ۶ ماه اخیر',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TrendLineChart(points: points, palette: palette),
        ],
      ),
    );
  }
}

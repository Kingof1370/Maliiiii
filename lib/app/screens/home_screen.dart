import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../branding.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/add_transfer_screen.dart';
import '../screens/transactions_screen.dart';
import '../state/ledger_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_backdrop.dart';
import '../widgets/premium_card.dart';

/// داشبورد اصلی (مرکز کنترل مالی).
///
/// تمام اعداد از [FinancialLedger] واقعی خوانده می‌شوند؛ در فازهای بعدی
/// ثبت داده به همین موتور متصل می‌شود. 3D در اینجا کاربردی است:
/// کارت‌های لایه‌ای، سایهٔ عمیق و میکرو-انیمیشن بدون سنگین‌کردن رندر.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    final UserProfile? profile = ProfileScope.of(context).profile;
    final DateTime today = DateTime.now();
    return PremiumBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: <Widget>[
            const _Header(),
            const SizedBox(height: AppDimensions.spaceMd),
            _BalanceHeroCard(ledger: ledger),
            const SizedBox(height: AppDimensions.spaceMd),
            _AvailableMoneyCard(ledger: ledger, today: today),
            const SizedBox(height: AppDimensions.spaceMd),
            _MetricGrid(ledger: ledger, today: today),
            const SizedBox(height: AppDimensions.spaceMd),
            _HealthAndForecast(ledger: ledger, today: today),
            const SizedBox(height: AppDimensions.spaceMd),
            _NotificationsCard(ledger: ledger, profile: profile, today: today),
            const SizedBox(height: AppDimensions.spaceMd),
            const _TransactionsEntry(),
            const SizedBox(height: AppDimensions.spaceLg),
            const _QuickAddCard(),
            const SizedBox(height: AppDimensions.spaceLg),
            const DeveloperFooter(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String _displayName(BuildContext context) {
    final String? name = ProfileScope.of(context).profile?.displayName;
    return (name == null || name.isEmpty) ? '' : name;
  }


  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'سلام ${_displayName(context)} 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'مالیار — ${Branding.tagline}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        _HeaderAvatar(palette: palette),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.primary, palette.gold.withValues(alpha: 0.7)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.account_balance_wallet_rounded,
          color: Colors.white, size: 24),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.ledger});

  final FinancialLedger ledger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return PremiumCard(
      elevation: PremiumElevation.floating,
      radius: AppDimensions.radiusXl,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[palette.primary, const Color(0xFF26366F)],
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 20),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                FaStrings.totalBalance,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    ledger.totalBalance() == const Money(0)
                        ? formatMinorUnits(0, suffix: '')
                        : formatMinorUnits(
                            ledger.totalBalance().minorUnits,
                            suffix: '',
                          ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'تومان',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              _HeroBadge(
                icon: Icons.arrow_upward_rounded,
                label: 'درآمد ماه',
                value: formatMinorUnits(0, suffix: ''),
                color: const Color(0xFF4ADE80),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              _HeroBadge(
                icon: Icons.arrow_downward_rounded,
                label: 'هزینهٔ ماه',
                value: formatMinorUnits(0, suffix: ''),
                color: const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceSm,
          vertical: AppDimensions.spaceSm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableMoneyCard extends StatelessWidget {
  const _AvailableMoneyCard({required this.ledger, required this.today});

  final FinancialLedger ledger;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return PremiumCard(
      elevation: PremiumElevation.raised,
      glass: true,
      accent: palette.gold,
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(Icons.savings_rounded, color: palette.gold, size: 22),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  FaStrings.availableMoney,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMinorUnits(
                    ledger
                        .availableMoney(asOf: today)
                        .minorUnits,
                    suffix: '',
                  ),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'تومان',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.ledger, required this.today});

  final FinancialLedger ledger;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final MonthlySummary summary = ledger.monthlySummary(today);
    final Money debt = ledger.outstandingDebt();
    final Money income = summary.income;
    final Money expense = summary.expense;
    final Money savings = income - expense;

    const List<_MetricSpec> specs = <_MetricSpec>[
      _MetricSpec('درآمد ماه', Icons.trending_up_rounded, null, null),
      _MetricSpec('هزینهٔ ماه', Icons.trending_down_rounded, null, null),
      _MetricSpec('پس‌انداز', Icons.savings_outlined, null, null),
      _MetricSpec('بدهی', Icons.credit_score_rounded, null, null),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spaceMd,
      crossAxisSpacing: AppDimensions.spaceMd,
      childAspectRatio: 1.55,
      children: <Widget>[
        _MetricCard(
          spec: specs[0],
          minorUnits: income.minorUnits,
          palette: context.appPalette,
        ),
        _MetricCard(
          spec: specs[1],
          minorUnits: expense.minorUnits,
          palette: context.appPalette,
        ),
        _MetricCard(
          spec: specs[2],
          minorUnits: savings.minorUnits,
          palette: context.appPalette,
        ),
        _MetricCard(
          spec: specs[3],
          minorUnits: debt.minorUnits,
          palette: context.appPalette,
        ),
      ],
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.icon, this.color, this.glow);

  final String label;
  final IconData icon;
  final Color? color;
  final Color? glow;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.spec,
    required this.minorUnits,
    required this.palette,
  });

  final _MetricSpec spec;
  final int minorUnits;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevation: PremiumElevation.raised,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(spec.icon, size: 20, color: palette.primary),
          const Spacer(),
          Text(
            spec.label,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMinorUnits(minorUnits, suffix: ''),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'تومان',
            style: TextStyle(color: palette.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _HealthAndForecast extends StatelessWidget {
  const _HealthAndForecast({required this.ledger, required this.today});

  final FinancialLedger ledger;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final FinancialHealthScore? score = _safeHealth(ledger, today);
    final Forecast? forecast =
        ledger.forecast(asOf: today, periodEnd: DateTime(2026, 8, 31));

    return Column(
      children: <Widget>[
        PremiumCard(
          elevation: PremiumElevation.raised,
          accent: palette.primary,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: (score?.value ?? 0) / 100,
                        strokeWidth: 7,
                        backgroundColor: palette.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (score?.value ?? 0) >= 70
                              ? palette.positive
                              : (score?.value ?? 0) >= 40
                                  ? palette.warning
                                  : palette.danger,
                        ),
                      ),
                    ),
                    Text(
                      '${score?.value ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'امتیاز سلامت مالی',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score?.explanation ??
                          'برای محاسبهٔ امتیاز، چند تراکنش ثبت کن.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        PremiumCard(
          elevation: PremiumElevation.raised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.auto_awesome_rounded,
                      color: palette.gold, size: 20),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Text(
                    'پیش‌بینی ماه',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                forecast == null
                    ? 'برای پیش‌بینی دقیق‌تر، چند روز/هفته اطلاعات مالی بیشتری ثبت کن.'
                    : 'موجودی پیش‌بینی‌شدهٔ پایان ماه: '
                        '${formatMinorUnits(forecast.expectedBalance.minorUnits)}',
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
    );
  }

  /// نسخهٔ امنِ خواندن امتیاز برای دادهٔ خالی (بدون throw).
  FinancialHealthScore? _safeHealth(FinancialLedger ledger, DateTime day) {
    try {
      return ledger.healthScore(day);
    } catch (_) {
      return null;
    }
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return PremiumCard(
      elevation: PremiumElevation.raised,
      accent: palette.positive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            FaStrings.noTransactionsYet,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'بودجه، هدف و گزارش بعد از ثبت اولین تراکنش فعال می‌شوند.',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  key: const Key('quick-add-expense'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddTransactionScreen(income: false),
                    ),
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('ثبت هزینه'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('quick-add-income'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddTransactionScreen(income: true),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('درآمد'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('quick-add-transfer'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddTransferScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('انتقال'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            FaStrings.foundationPhaseNote,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// کارت اعلان‌های هوشمند: از موتور خالص [buildNotifications] با لحن پروفایل
/// ساخته می‌شود؛ داده‌ها همیشه از دفترکل واقعی خوانده می‌شوند.
class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.ledger,
    required this.profile,
    required this.today,
  });

  final FinancialLedger ledger;
  final UserProfile? profile;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final UserProfile? current = profile;
    if (current == null) return const SizedBox.shrink();
    final List<AppNotification> all = buildNotifications(
      ledger: ledger,
      profile: current,
      asOf: today,
    );
    if (all.isEmpty) {
      return PremiumCard(
        elevation: PremiumElevation.flat,
        child: Row(
          children: <Widget>[
            Icon(Icons.verified_rounded, color: palette.positive),
            const SizedBox(width: AppDimensions.spaceSm + 4),
            Expanded(
              child: Text(
                'همه‌چیز رو به راه است 👌',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final List<AppNotification> shown = all.take(4).toList();
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.notifications_active_rounded,
                  color: palette.gold, size: 20),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'اعلان‌های هوشمند',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  toPersianDigits(all.length),
                  style: TextStyle(
                    color: palette.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm + 4),
          for (final AppNotification n in shown) ...<Widget>[
            _NotificationTile(notification: n),
            if (n != shown.last) Divider(color: palette.divider, height: 1),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData _icon(NotificationPriority priority) => switch (priority) {
        NotificationPriority.urgent => Icons.error_rounded,
        NotificationPriority.high => Icons.warning_amber_rounded,
        NotificationPriority.normal => Icons.info_outline_rounded,
        NotificationPriority.low => Icons.notifications_none_rounded,
      };

  Color _color(AppPalette palette, NotificationPriority priority) =>
      switch (priority) {
        NotificationPriority.urgent => palette.danger,
        NotificationPriority.high => palette.warning,
        NotificationPriority.normal => palette.info,
        NotificationPriority.low => palette.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            _icon(notification.priority),
            color: _color(palette, notification.priority),
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spaceSm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12.5,
                    height: 1.4,
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

/// ورودی «تاریخچهٔ تراکنش‌ها» از داشبورد با شمارندهٔ تراکنش‌ها.
class _TransactionsEntry extends StatelessWidget {
  const _TransactionsEntry();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    return PremiumCard(
      key: const Key('transactions-entry'),
      elevation: PremiumElevation.flat,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TransactionListScreen(),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.receipt_long_outlined, color: palette.primary),
          const SizedBox(width: AppDimensions.spaceSm + 4),
          const Expanded(
            child: Text(
              'تاریخچهٔ تراکنش‌ها',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
            child: Text(
              toPersianDigits(ledger.transactions.length),
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Icon(Icons.chevron_left_rounded, color: palette.textMuted),
        ],
      ),
    );
  }
}

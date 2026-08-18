import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/budget_controller.dart';
import '../state/budget_scope.dart';
import '../state/loan_format.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'add_budget_screen.dart';
import 'add_recurring_screen.dart';

/// تب بودجه: سقف/مصرف واقعی، کارت هر بودجه و تراکنش‌های تکرارشونده با
/// ثبت خودکار سررسیدها.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  String _frequencyLabel(RecurringFrequency frequency) => switch (frequency) {
        RecurringFrequency.daily => 'روزانه',
        RecurringFrequency.weekly => 'هفتگی',
        RecurringFrequency.monthly => 'ماهانه',
        RecurringFrequency.yearly => 'سالانه',
      };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final BudgetController controller = BudgetScope.of(context);
    final List<Budget> budgets = controller.budgets;
    final int totalBudget =
        budgets.fold<int>(0, (sum, item) => sum + item.amount.minorUnits);
    final int totalSpent = budgets.fold<int>(
      0,
      (sum, item) => sum + controller.spentOf(item).minorUnits,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'بودجه و تکرارشونده‌ها',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filled(
                key: const Key('add-budget-button'),
                tooltip: 'بودجه جدید',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddBudgetScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          PremiumCard(
            elevation: PremiumElevation.raised,
            accent: palette.primary,
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.savings_rounded, color: palette.primary),
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'سقف بودجهٔ فعال',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMinorUnits(totalBudget),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'مصرف‌شده',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMinorUnits(totalSpent),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: totalSpent > totalBudget
                            ? palette.danger
                            : palette.positive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          if (budgets.isEmpty)
            const _EmptyBudgets()
          else
            for (final Budget budget in budgets)
              _BudgetCard(
                budget: budget,
                spent: controller.spentOf(budget),
              ),
          const SizedBox(height: AppDimensions.spaceLg),
          Row(
            children: <Widget>[
              Text(
                'تراکنش‌های تکرارشونده',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filled(
                key: const Key('add-recurring-button'),
                tooltip: 'تراکنش تکرارشونده',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddRecurringScreen(),
                  ),
                ),
                icon: const Icon(Icons.repeat),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          FilledButton.tonalIcon(
            key: const Key('materialize-button'),
            onPressed: () async {
              final int count =
                  await controller.materializeDue(asOf: DateTime.now());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? 'تراکنش سررسیدشده‌ای برای ثبت نبود.'
                        : '${toPersianDigits(count)} تراکنش تکرارشونده ثبت شد.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('ثبت خودکار سررسیدها'),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (controller.recurrings.isEmpty)
            Text(
              'هنوز تراکنش تکرارشونده‌ای ثبت نشده است.',
              style: TextStyle(color: palette.textMuted, fontSize: 13),
            )
          else
            for (final RecurringTransaction recurring
                in controller.recurrings)
              _RecurringTile(
                recurring: recurring,
                frequencyLabel: _frequencyLabel(recurring.frequency),
              ),
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.spent});

  final Budget budget;
  final Money spent;

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف بودجه'),
        content: Text('بودجهٔ «${budget.name}» حذف شود؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await BudgetScope.of(context).deleteBudget(budgetId: budget.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بودجه حذف شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final int limit = budget.amount.minorUnits;
    final int used = spent.minorUnits;
    final double progress = limit == 0 ? 0 : (used / limit).clamp(0.0, 1.0);
    final bool over = used > limit;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: PremiumCard(
        elevation: PremiumElevation.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    budget.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  key: Key('delete-budget-${budget.id}'),
                  tooltip: 'حذف بودجه',
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
            Text(
              budget.category ?? 'همهٔ هزینه‌ها',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            Text(
              '${formatJalaliDate(budget.startDate)} تا '
              '${formatJalaliDate(budget.endDate)}',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: <Widget>[
                Text(
                  'مصرف‌شده: ${formatMinorUnits(used)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: over ? palette.danger : palette.positive,
                  ),
                ),
                const Spacer(),
                Text(
                  'سقف: ${formatMinorUnits(limit)}',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: palette.primary.withValues(alpha: 0.12),
                color: over ? palette.danger : palette.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              over
                  ? 'مازاد: ${formatMinorUnits(used - limit)}'
                  : 'باقی‌مانده: ${formatMinorUnits(limit - used)}',
              style: TextStyle(
                fontSize: 12,
                color: over ? palette.danger : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.recurring,
    required this.frequencyLabel,
  });

  final RecurringTransaction recurring;
  final String frequencyLabel;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final bool income = recurring.isIncome;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: PremiumCard(
        elevation: PremiumElevation.flat,
        child: Row(
          children: <Widget>[
            Icon(
              income ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: income ? palette.positive : palette.danger,
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recurring.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$frequencyLabel' +
                        (recurring.category == null
                            ? ''
                            : ' · ${recurring.category}'),
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatMinorUnits(recurring.amount.minorUnits),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Switch(
                  key: Key('rec-active-${recurring.id}'),
                  value: recurring.active,
                  onChanged: (bool value) =>
                      BudgetScope.of(context).toggleRecurring(
                    recurringId: recurring.id,
                    active: value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.savings_rounded, size: 52, color: palette.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'هنوز بودجه‌ای ثبت نشده است',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'با دکمهٔ بالا بودجه تعریف کن و خرج‌کردت را کنترل کن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/goal_controller.dart';
import '../state/goal_scope.dart';
import '../state/loan_format.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'add_goal_screen.dart';

/// تب اهداف: سقف/پیشرفت واقعی، کارت هر هدف با مشارکت و حذف.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final GoalController controller = GoalScope.of(context);
    final List<Goal> goals = controller.goals;
    final int total = controller.totalTarget.minorUnits;
    final int current = controller.totalCurrent.minorUnits;
    final double overall = total == 0 ? 0 : (current / total).clamp(0.0, 1.0);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'اهداف مالی',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filled(
                key: const Key('add-goal-button'),
                tooltip: 'هدف جدید',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddGoalScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          PremiumCard(
            elevation: PremiumElevation.raised,
            accent: palette.gold,
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.gold.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.flag_rounded, color: palette.gold),
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'پیشرفت کل اهداف',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatMinorUnits(current)} از ${formatMinorUnits(total)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${toPersianDigits((overall * 100).round())}٪',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.gold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          if (goals.isEmpty)
            const _EmptyGoals()
          else
            for (final Goal goal in goals)
              _GoalCard(goal: goal),
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  static const Map<GoalType, IconData> _icons = <GoalType, IconData>{
    GoalType.savings: Icons.savings_rounded,
    GoalType.purchase: Icons.shopping_cart_rounded,
    GoalType.income: Icons.trending_up_rounded,
    GoalType.debtReduction: Icons.credit_score_rounded,
    GoalType.investment: Icons.account_balance_rounded,
    GoalType.custom: Icons.flag_rounded,
  };

  String _typeLabel(GoalType type) => switch (type) {
        GoalType.savings => 'پس‌انداز',
        GoalType.purchase => 'خرید',
        GoalType.income => 'درآمد',
        GoalType.debtReduction => 'کاهش بدهی',
        GoalType.investment => 'سرمایه‌گذاری',
        GoalType.custom => 'سفارشی',
      };

  static const Map<int, String> _priorityLabels = <int, String>{
    1: 'خیلی کم',
    2: 'کم',
    3: 'متوسط',
    4: 'زیاد',
    5: 'خیلی زیاد',
  };

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف هدف'),
        content: Text('هدف «${goal.name}» حذف شود؟'),
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
    await GoalScope.of(context).deleteGoal(goalId: goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هدف حذف شد.')),
    );
  }

  void _contribute(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContributeSheet(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final int target = goal.target.minorUnits;
    final int current = goal.current.minorUnits;
    final double progress =
        target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
    final bool done = current >= target && target > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: PremiumCard(
        key: Key('goal-card-${goal.id}'),
        elevation: PremiumElevation.raised,
        accent: done ? palette.positive : palette.gold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_icons[goal.type], color: palette.primary, size: 22),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  key: Key('goal-delete-${goal.id}'),
                  tooltip: 'حذف هدف',
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
            Text(
              '${_typeLabel(goal.type)} · اولویت: ${_priorityLabels[goal.priority] ?? ''}',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
            Text(
              'سررسید: ${formatJalaliDate(goal.deadline)}',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: <Widget>[
                Text(
                  '${formatMinorUnits(current)} از ${formatMinorUnits(target)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  done ? 'تکمیل‌شده 🎉' : '${toPersianDigits((progress * 100).round())}٪',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: done ? palette.positive : palette.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: palette.primary.withValues(alpha: 0.12),
                color: done ? palette.positive : palette.gold,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            if (!done)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  key: Key('goal-contribute-${goal.id}'),
                  onPressed: () => _contribute(context),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('افزایش پیشرفت'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  const _ContributeSheet({required this.goal});

  final Goal goal;

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.goal.remaining.minorUnits.toString(),
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final int? amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'مبلغ معتبر نیست.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GoalScope.of(context).contribute(
        goalId: widget.goal.id,
        amount: Money(amount),
      );
      if (mounted) Navigator.of(context).pop();
    } on FinancialValidationException catch (error) {
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'افزایش پیشرفت «${widget.goal.name}»',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'باقی‌مانده: ${formatMinorUnits(widget.goal.remaining.minorUnits)}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            TextField(
              key: const Key('goal-contribute-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                prefixIcon: Icon(Icons.payments_outlined),
                counterText: '',
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppDimensions.spaceMd),
              Text(
                _error!,
                style: TextStyle(color: palette.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceLg),
            FilledButton.icon(
              key: const Key('goal-contribute-submit'),
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(_busy ? 'در حال ثبت...' : 'ثبت'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.flag_rounded, size: 52, color: palette.gold),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'هنوز هدفی ثبت نشده است',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'برای خرید، پس‌انداز یا هر آرزوی مالی هدف بساز.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

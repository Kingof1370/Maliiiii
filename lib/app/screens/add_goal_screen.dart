import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';
import '../state/goal_scope.dart';
import '../widgets/jalali_date_field.dart';

/// فرم ثبت هدف مالی با نوع، سقف، سررسید شمسی و اولویت.
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _target = TextEditingController();
  GoalType _type = GoalType.savings;
  JalaliDate _deadline = JalaliDate.today().addMonths(12);
  int _priority = 3;

  static const Map<GoalType, (String, IconData)> _types = <GoalType, (String, IconData)>{
    GoalType.savings: ('پس‌انداز', Icons.savings_rounded),
    GoalType.purchase: ('خرید', Icons.shopping_cart_rounded),
    GoalType.income: ('درآمد', Icons.trending_up_rounded),
    GoalType.debtReduction: ('کاهش بدهی', Icons.credit_score_rounded),
    GoalType.investment: ('سرمایه‌گذاری', Icons.trending_up_rounded),
    GoalType.custom: ('سفارشی', Icons.flag_rounded),
  };

  static const Map<int, String> _priorityLabels = <int, String>{
    1: 'خیلی کم',
    2: 'کم',
    3: 'متوسط',
    4: 'زیاد',
    5: 'خیلی زیاد',
  };

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      await GoalScope.of(context).createGoal(
        goal: Goal(
          id: 'goal-${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          type: _type,
          target: Money(int.parse(_target.text.trim())),
          current: const Money(0),
          deadline: _deadline.toGregorian(),
          priority: _priority,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on FinancialValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('هدف جدید')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              TextFormField(
                key: const Key('goal-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'نام هدف',
                  prefixIcon: Icon(Icons.flag_outlined),
                  counterText: '',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'نام هدف نمی‌تواند خالی باشد.'
                        : null,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('goal-target'),
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'سقف هدف (تومان)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  counterText: '',
                ),
                validator: (String? value) {
                  final int? parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'سقف باید بزرگ‌تر از صفر باشد.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text(
                'نوع هدف',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final GoalType type in GoalType.values)
                    ChoiceChip(
                      key: Key('goal-type-${type.name}'),
                      avatar: Icon(_types[type]!.$2, size: 18),
                      label: Text(_types[type]!.$1),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _deadline,
                onChanged: (JalaliDate date) =>
                    setState(() => _deadline = date),
                label: 'سررسید هدف',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              DropdownButtonFormField<int>(
                key: const Key('goal-priority'),
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'اولویت',
                  prefixIcon: Icon(Icons.priority_high_rounded),
                  counterText: '',
                ),
                items: <DropdownMenuItem<int>>[
                  for (final int priority in _priorityLabels.keys)
                    DropdownMenuItem<int>(
                      value: priority,
                      child: Text(_priorityLabels[priority]!),
                    ),
                ],
                onChanged: (int? value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('goal-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت هدف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

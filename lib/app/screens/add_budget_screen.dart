import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';
import '../state/budget_scope.dart';
import '../state/categories.dart';
import '../state/category_controller.dart';
import '../state/category_scope.dart';
import '../widgets/jalali_date_field.dart';

/// فرم ثبت بودجه با بازهٔ شمسی و دستهٔ اختیاری.
class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  String _category = '_all';
  JalaliDate _start = JalaliDate.today();
  JalaliDate _end = JalaliDate.today().addMonths(1);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    try {
      await BudgetScope.of(context).createBudget(
        budget: Budget(
          id: 'budget-${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          amount: Money(int.parse(_amount.text.trim())),
          startDate: _start.toGregorian(),
          endDate: _end.toGregorian(),
          category: _category == '_all' ? null : _category,
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
      appBar: AppBar(title: const Text('بودجهٔ جدید')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              TextFormField(
                key: const Key('budget-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'نام بودجه',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  counterText: '',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'نام بودجه نمی‌تواند خالی باشد.'
                        : null,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('budget-amount'),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'سقف بودجه (تومان)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  counterText: '',
                ),
                validator: (String? value) {
                  final int? parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'مبلغ باید بزرگ‌تر از صفر باشد.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              DropdownButtonFormField<String>(
                key: const Key('budget-category'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'دسته',
                  prefixIcon: Icon(Icons.category_outlined),
                  counterText: '',
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: '_all',
                    child: Text('همهٔ هزینه‌ها'),
                  ),
                  for (final String category in _expenseCategories(context))
                    DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                ],
                onChanged: (String? value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _start,
                onChanged: (JalaliDate date) => setState(() => _start = date),
                label: 'تاریخ شروع',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _end,
                onChanged: (JalaliDate date) => setState(() => _end = date),
                label: 'تاریخ پایان',
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('budget-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت بودجه'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دسته‌های پیش‌فرض هزینه + دسته‌های سفارشی کاربر (بدون تکرار).
List<String> _expenseCategories(BuildContext context) {
  final List<String> defaults = DefaultCategories.expense;
  final CategoryController controller = CategoryScope.of(context);
  final Set<String> seen = <String>{
    ...defaults,
    for (final UserCategory custom in controller.expense) custom.name,
  };
  return seen.toList();
}

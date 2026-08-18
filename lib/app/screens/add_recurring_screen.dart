import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';
import '../state/account_scope.dart';
import '../state/budget_scope.dart';
import '../state/categories.dart';
import '../widgets/jalali_date_field.dart';

/// فرم ثبت تراکنش تکرارشونده (درآمد/هزینه) با بازهٔ شمسی.
class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  TransactionKind _kind = TransactionKind.expense;
  String? _accountId;
  String _category = '_all';
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  JalaliDate _start = JalaliDate.today();
  bool _active = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final List<Account> accounts = AccountScope.of(context).accounts;
      if (accounts.length == 1) _accountId = accounts.single.id;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String _frequencyLabel(RecurringFrequency frequency) => switch (frequency) {
        RecurringFrequency.daily => 'روزانه',
        RecurringFrequency.weekly => 'هفتگی',
        RecurringFrequency.monthly => 'ماهانه',
        RecurringFrequency.yearly => 'سالانه',
      };

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا حساب را انتخاب کنید.')),
      );
      return;
    }
    try {
      await BudgetScope.of(context).createRecurring(
        recurring: RecurringTransaction(
          id: 'rec-${DateTime.now().microsecondsSinceEpoch}',
          name: _name.text.trim(),
          amount: Money(int.parse(_amount.text.trim())),
          kind: _kind,
          accountId: _accountId!,
          frequency: _frequency,
          startDate: _start.toGregorian(),
          category: _category == '_all' ? null : _category,
          active: _active,
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
    final List<Account> accounts = AccountScope.of(context).accounts;
    final List<String> categories = _kind == TransactionKind.income
        ? DefaultCategories.income
        : DefaultCategories.expense;

    return Scaffold(
      appBar: AppBar(title: const Text('تراکنش تکرارشونده')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              TextFormField(
                key: const Key('rec-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'نام',
                  prefixIcon: Icon(Icons.repeat),
                  counterText: '',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'نام نمی‌تواند خالی باشد.'
                        : null,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('rec-amount'),
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
                validator: (String? value) {
                  final int? parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'مبلغ باید بزرگ‌تر از صفر باشد.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SegmentedButton<TransactionKind>(
                key: const Key('rec-kind'),
                segments: const <ButtonSegment<TransactionKind>>[
                  ButtonSegment<TransactionKind>(
                    value: TransactionKind.expense,
                    label: Text('هزینه'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                  ButtonSegment<TransactionKind>(
                    value: TransactionKind.income,
                    label: Text('درآمد'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                ],
                selected: <TransactionKind>{_kind},
                onSelectionChanged: (Set<TransactionKind> selection) {
                  setState(() {
                    _kind = selection.first;
                    _category = '_all';
                  });
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              DropdownButtonFormField<String>(
                key: const Key('rec-account'),
                initialValue: _accountId,
                decoration: const InputDecoration(
                  labelText: 'حساب',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  counterText: '',
                ),
                items: <DropdownMenuItem<String>>[
                  for (final Account account in accounts)
                    DropdownMenuItem<String>(
                      value: account.id,
                      child: Text(account.name),
                    ),
                ],
                onChanged: (String? value) =>
                    setState(() => _accountId = value),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              DropdownButtonFormField<String>(
                key: const Key('rec-category'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'دسته',
                  prefixIcon: Icon(Icons.category_outlined),
                  counterText: '',
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: '_all',
                    child: Text('بدون دسته'),
                  ),
                  for (final String category in categories)
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
              DropdownButtonFormField<RecurringFrequency>(
                key: const Key('rec-frequency'),
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'بازهٔ تکرار',
                  prefixIcon: Icon(Icons.event_repeat_rounded),
                  counterText: '',
                ),
                items: <DropdownMenuItem<RecurringFrequency>>[
                  for (final RecurringFrequency frequency
                      in RecurringFrequency.values)
                    DropdownMenuItem<RecurringFrequency>(
                      value: frequency,
                      child: Text(_frequencyLabel(frequency)),
                    ),
                ],
                onChanged: (RecurringFrequency? frequency) {
                  if (frequency != null) {
                    setState(() => _frequency = frequency);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _start,
                onChanged: (JalaliDate date) => setState(() => _start = date),
                label: 'تاریخ شروع',
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              SwitchListTile(
                key: const Key('rec-active'),
                contentPadding: EdgeInsets.zero,
                title: const Text('فعال'),
                value: _active,
                onChanged: (bool value) => setState(() => _active = value),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('rec-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

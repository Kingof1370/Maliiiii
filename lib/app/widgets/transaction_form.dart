import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../state/categories.dart';
import '../state/category_controller.dart';
import '../state/category_scope.dart';
import '../theme/app_theme.dart';
import 'premium_card.dart';


enum TransactionFormKind { income, expense }

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.kind,
    required this.onDone,
    this.initialAccountId,
    this.initialAmount = 0,
    this.initialCategory,
    this.initialDescription = '',
    this.submitLabel,
  });

  final TransactionFormKind kind;
  final Future<void> Function(
    String accountId,
    int amountMinorUnits,
    String category,
    String description,
  ) onDone;

  final String? initialAccountId;
  final int initialAmount;
  final String? initialCategory;
  final String initialDescription;
  final String? submitLabel;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String? _accountId;
  String? _category;
  bool _saving = false;

  bool get _isIncome => widget.kind == TransactionFormKind.income;
  List<String> _categoriesOf(BuildContext context) {
    final CategoryController controller = CategoryScope.of(context);
    final List<String> defaults = _isIncome
        ? DefaultCategories.income
        : DefaultCategories.expense;
    final List<String> all = <String>[
      ...defaults,
      for (final UserCategory custom in controller.categories)
        if ((_isIncome && custom.kind == CategoryKind.income) ||
            (!_isIncome && custom.kind == CategoryKind.expense))
          custom.name,
    ];
    final Set<String> seen = <String>{};
    return <String>[
      for (final String name in all)
        if (seen.add(name)) name,
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      _amount.text = widget.initialAmount.toString();
    }
    _description.text = widget.initialDescription;
    _accountId = widget.initialAccountId;
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory(BuildContext context) async {
    final TextEditingController text = TextEditingController();
    final CategoryKind kind = widget.kind == TransactionFormKind.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final String? name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          kind == CategoryKind.income ? 'دستهٔ درآمد جدید' : 'دستهٔ هزینهٔ جدید',
        ),
        content: TextField(
          key: const Key('new-category-name'),
          controller: text,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام دسته'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            key: const Key('new-category-save'),
            onPressed: () => Navigator.pop(dialogContext, text.text.trim()),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final CategoryController controller = CategoryScope.of(context);
      await controller.add(
        id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        kind: kind,
      );
      if (mounted) setState(() => _category = name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یک حساب انتخاب کنید.')),
      );
      return;
    }
    final int amount = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      await widget.onDone(
        _accountId!,
        amount,
        _category ?? (_isIncome ? 'سایر' : 'سایر'),
        _description.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final AccountController controller = AccountScope.of(context);
    final List<String> categories = _categoriesOf(context);
    final List<String> accountOptions = <String>[
      for (final Account account in controller.accounts) account.name,
    ];

    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              key: const Key('tx-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'مبلغ (تومان)',
                prefixIcon: Icon(
                  _isIncome ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: _isIncome ? palette.positive : palette.danger,
                ),
                counterText: '',
              ),
              validator: (value) {
                final int amount = int.tryParse(
                      (value ?? '').replaceAll(',', ''),
                    ) ??
                    0;
                return amount <= 0 ? 'مبلغ معتبر وارد کنید.' : null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            DropdownButtonFormField<String>(
              key: const Key('tx-account'),
              initialValue: _accountId,
              hint: const Text('انتخاب حساب'),
              items: <DropdownMenuItem<String>>[
                for (int index = 0; index < accountOptions.length; index++)
                  DropdownMenuItem<String>(
                    value: controller.accounts[index].id,
                    child: Text(accountOptions[index]),
                  ),
              ],
              onChanged: (String? value) => setState(() => _accountId = value),
              decoration: const InputDecoration(
                labelText: 'حساب',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: <Widget>[
                const Spacer(),
                TextButton.icon(
                  key: const Key('tx-new-category'),
                  onPressed: () => _addNewCategory(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('دستهٔ جدید'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            DropdownButtonFormField<String>(
              key: const Key('tx-category'),
              initialValue: _category,
              hint: const Text('انتخاب دسته'),
              items: <DropdownMenuItem<String>>[
                for (final String category in categories)
                  DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (String? value) => setState(() => _category = value),
              decoration: const InputDecoration(
                labelText: 'دسته',
                prefixIcon: Icon(Icons.category_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            TextFormField(
              key: const Key('tx-description'),
              controller: _description,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'توضیح (اختیاری)',
                prefixIcon: Icon(Icons.notes_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('tx-submit'),
                onPressed: _submit,
                icon: Icon(
                  _isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                ),
                label: Text(widget.submitLabel ?? (_isIncome ? 'ثبت درآمد' : 'ثبت هزینه')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

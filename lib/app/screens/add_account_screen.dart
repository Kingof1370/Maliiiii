import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_card.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _opening = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  AccountType _type = AccountType.cash;

  static const Map<AccountType, (String, IconData)> _types =
      <AccountType, (String, IconData)>{
    AccountType.bank: ('بانک', Icons.account_balance_rounded),
    AccountType.card: ('کارت', Icons.credit_card_rounded),
    AccountType.cash: ('نقدی', Icons.payments_rounded),
    AccountType.savings: ('پس‌انداز', Icons.savings_rounded),
    AccountType.wallet: ('کیف پول', Icons.wallet_rounded),
    AccountType.investment: ('سرمایه‌گذاری', Icons.trending_up_rounded),
  };

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final String name = _name.text.trim();
    final String openingRaw = _opening.text.replaceAll(',', '').trim();
    final String notes = _notes.text.trim();
    final int opening = int.tryParse(openingRaw) ?? 0;
    final String id = 'acc-${DateTime.now().millisecondsSinceEpoch}';

    final AccountController controller = AccountScope.of(context);
    try {
      await controller.addAccount(
        id: id,
        name: name,
        type: _type,
        openingMinorUnits: opening,
        notes: notes.isEmpty ? null : notes,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ثبت حساب ناموفق بود: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Scaffold(
      appBar: AppBar(title: const Text('حساب جدید')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          PremiumCard(
            elevation: PremiumElevation.raised,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    key: const Key('account-name'),
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'نام حساب',
                      hintText: 'مثلاً بانک ملی',
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                      counterText: '',
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'نام حساب نمی‌تواند خالی باشد.'
                        : null,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  TextFormField(
                    key: const Key('account-opening'),
                    controller: _opening,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'موجودی اولیه (تومان)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  Text(
                    'نوع حساب',
                    style: TextStyle(color: palette.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final AccountType type in AccountType.values)
                        ChoiceChip(
                          key: Key('account-type-${type.name}'),
                          avatar: Icon(_types[type]!.$2, size: 18),
                          label: Text(_types[type]!.$1),
                          selected: _type == type,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  TextFormField(
                    key: const Key('account-notes'),
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت (اختیاری)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('account-save'),
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('ذخیرهٔ حساب'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

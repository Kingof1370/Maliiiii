import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_card.dart';

class AddTransferScreen extends StatefulWidget {
  const AddTransferScreen({super.key});

  @override
  State<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends State<AddTransferScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String? _fromId;
  String? _toId;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حساب مبدأ و مقصد را انتخاب کنید.')),
      );
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حساب مبدأ و مقصد باید متفاوت باشند.')),
      );
      return;
    }
    final int amount = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      await AccountScope.of(context).recordTransfer(
        transferId: 'tr-${DateTime.now().microsecondsSinceEpoch}',
        fromAccountId: _fromId!,
        toAccountId: _toId!,
        amountMinorUnits: amount,
        date: DateTime.now(),
        description: _description.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('انتقال ناموفق بود: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final List<Account> accounts = AccountScope.of(context).accounts;

    return Scaffold(
      appBar: AppBar(title: const Text('انتقال بین حساب‌ها')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          if (accounts.length < 2)
            PremiumCard(
              child: Text(
                'برای انتقال، حداقل دو حساب بسازید.',
                style: TextStyle(color: palette.textSecondary),
              ),
            )
          else
            PremiumCard(
              elevation: PremiumElevation.raised,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      key: const Key('transfer-from'),
                      initialValue: _fromId,
                      hint: const Text('از حساب'),
                      items: <DropdownMenuItem<String>>[
                        for (final Account account in accounts)
                          DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                      ],
                      onChanged: (String? value) =>
                          setState(() => _fromId = value),
                      decoration: const InputDecoration(
                        labelText: 'از حساب',
                        prefixIcon: Icon(Icons.arrow_upward_rounded),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    DropdownButtonFormField<String>(
                      key: const Key('transfer-to'),
                      initialValue: _toId,
                      hint: const Text('به حساب'),
                      items: <DropdownMenuItem<String>>[
                        for (final Account account in accounts)
                          DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                      ],
                      onChanged: (String? value) => setState(() => _toId = value),
                      decoration: const InputDecoration(
                        labelText: 'به حساب',
                        prefixIcon: Icon(Icons.arrow_downward_rounded),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    TextFormField(
                      key: const Key('transfer-amount'),
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style:
                          const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'مبلغ (تومان)',
                        prefixIcon: Icon(Icons.payments_outlined),
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
                    TextFormField(
                      key: const Key('transfer-description'),
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
                        key: const Key('transfer-submit'),
                        onPressed: _save,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('ثبت انتقال'),
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

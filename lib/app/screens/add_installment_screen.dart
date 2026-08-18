import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';
import '../state/loan_controller.dart';
import '../state/loan_scope.dart';
import '../widgets/jalali_date_field.dart';

/// فرم افزودن قسط (نامنظم) به یک وام؛ چند قسط در یک روز مجاز است.
class AddInstallmentScreen extends StatefulWidget {
  const AddInstallmentScreen({super.key, required this.loanId});

  final String loanId;

  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  JalaliDate _date = JalaliDate.today();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final int amount = int.parse(_amount.text.trim());
    final LoanController controller = LoanScope.of(context);
    final Loan? loan = controller.loanById(widget.loanId);
    final int nextNumber = loan == null
        ? 1
        : loan.installments.fold<int>(
              0,
              (int max, Installment item) =>
                  item.number > max ? item.number : max,
            ) +
            1;
    try {
      await controller.addInstallment(
        loanId: widget.loanId,
        installment: Installment(
          id: 'inst-${DateTime.now().microsecondsSinceEpoch}',
          loanId: widget.loanId,
          number: nextNumber,
          dueDate: _date.toGregorian(),
          totalAmount: Money(amount),
          notes: _note.text.trim(),
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
      appBar: AppBar(title: const Text('قسط جدید')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              TextFormField(
                key: const Key('inst-amount'),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'مبلغ قسط (تومان)',
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
              JalaliDateField(
                value: _date,
                onChanged: (JalaliDate date) => setState(() => _date = date),
                label: 'سررسید قسط',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('inst-note'),
                controller: _note,
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
                  key: const Key('inst-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت قسط'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

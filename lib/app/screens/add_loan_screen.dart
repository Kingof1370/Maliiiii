import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';
import '../state/loan_scope.dart';
import '../widgets/jalali_date_field.dart';

/// فرم ثبت وام جدید با سود/کارمزد و برنامهٔ خودکار اختیاری اقساط شمسی.
class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _lender = TextEditingController();
  final TextEditingController _principal = TextEditingController();
  final TextEditingController _interest = TextEditingController();
  final TextEditingController _fees = TextEditingController();
  final TextEditingController _received = TextEditingController();
  final TextEditingController _count = TextEditingController(text: '12');
  bool _autoSchedule = false;
  JalaliDate _start = JalaliDate.today();
  JalaliDate _firstDue = JalaliDate.today().addMonths(1);

  @override
  void dispose() {
    _title.dispose();
    _lender.dispose();
    _principal.dispose();
    _interest.dispose();
    _fees.dispose();
    _received.dispose();
    _count.dispose();
    super.dispose();
  }

  int _amountOf(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _amountValidator(String? value, {bool positive = true}) {
    final int? parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'مبلغ معتبر نیست.';
    if (positive && parsed <= 0) return 'مبلغ باید بزرگ‌تر از صفر باشد.';
    if (parsed < 0) return 'مبلغ نمی‌تواند منفی باشد.';
    return null;
  }

  /// اعتبارسنجی مبلغ اختیاری؛ خالی مجاز است (صفر در نظر گرفته می‌شود).
  String? _optionalAmountValidator(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return _amountValidator(trimmed, positive: false);
  }

  Widget _amountField({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        key: key,
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.payments_outlined),
          counterText: '',
        ),
        validator: validator,
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final int principal = _amountOf(_principal);
    final int interest = _amountOf(_interest);
    final int fees = _amountOf(_fees);
    final int total = principal + interest + fees;
    final int received = _amountOf(_received) == 0 ? principal : _amountOf(_received);
    final String loanId = 'loan-${DateTime.now().microsecondsSinceEpoch}';
    final List<Installment> schedule = _autoSchedule
        ? LoanSchedule.equalMonthly(
            loanId: loanId,
            count: int.parse(_count.text.trim()),
            totalPayable: Money(total),
            firstDue: _firstDue,
          )
        : const <Installment>[];
    try {
      await LoanScope.of(context).createLoan(
        loan: Loan(
          id: loanId,
          title: _title.text.trim(),
          lender: _lender.text.trim(),
          principal: Money(principal),
          receivedAmount: Money(received),
          interest: Money(interest),
          fees: Money(fees),
          totalPayable: Money(total),
          startDate: _start.toGregorian(),
          installments: schedule,
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
    final int total =
        _amountOf(_principal) + _amountOf(_interest) + _amountOf(_fees);
    return Scaffold(
      appBar: AppBar(title: const Text('وام جدید')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            children: <Widget>[
              TextFormField(
                key: const Key('loan-title'),
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'عنوان وام',
                  prefixIcon: Icon(Icons.request_quote_outlined),
                  counterText: '',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'عنوان وام نمی‌تواند خالی باشد.'
                        : null,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('loan-lender'),
                controller: _lender,
                decoration: const InputDecoration(
                  labelText: 'وام‌دهنده (اختیاری)',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _amountField(
                key: const Key('loan-principal'),
                controller: _principal,
                label: 'مبلغ اصلی وام (تومان)',
                validator: _amountValidator,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _amountField(
                key: const Key('loan-interest'),
                controller: _interest,
                label: 'سود (تومان)',
                validator: _optionalAmountValidator,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _amountField(
                key: const Key('loan-fees'),
                controller: _fees,
                label: 'کارمزد (تومان)',
                validator: _optionalAmountValidator,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _amountField(
                key: const Key('loan-received'),
                controller: _received,
                label: 'مبلغ دریافتی (خالی = کل وام)',
                validator: _optionalAmountValidator,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  'مبلغ کل بدهی: ${formatMinorUnits(total)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _start,
                onChanged: (JalaliDate date) => setState(() => _start = date),
                label: 'تاریخ شروع وام',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SwitchListTile(
                key: const Key('loan-auto-schedule'),
                contentPadding: EdgeInsets.zero,
                title: const Text('ایجاد خودکار اقساط'),
                subtitle: const Text('قسط‌های مساوی ماهانهٔ شمسی'),
                value: _autoSchedule,
                onChanged: (bool value) =>
                    setState(() => _autoSchedule = value),
              ),
              if (_autoSchedule) ...<Widget>[
                const SizedBox(height: AppDimensions.spaceSm),
                TextFormField(
                  key: const Key('loan-installments-count'),
                  controller: _count,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'تعداد اقساط',
                    prefixIcon: Icon(Icons.grid_view_rounded),
                    counterText: '',
                  ),
                  validator: (String? value) {
                    final int? parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 1) {
                      return 'تعداد باید حداقل ۱ باشد.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                JalaliDateField(
                  value: _firstDue,
                  onChanged: (JalaliDate date) =>
                      setState(() => _firstDue = date),
                  label: 'سررسید قسط اول',
                ),
              ],
              const SizedBox(height: AppDimensions.spaceLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('loan-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت وام'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

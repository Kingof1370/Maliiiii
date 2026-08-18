import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_scope.dart';
import '../state/loan_controller.dart';
import '../state/loan_format.dart';
import '../state/loan_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/jalali_date_field.dart';
import '../widgets/premium_card.dart';
import 'add_installment_screen.dart';

/// جزئیات یک وام: وضعیت، پیشرفت و فهرست قسط‌ها با پرداخت/تغییر سررسید/لغو.
class LoanDetailScreen extends StatelessWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final LoanController controller = LoanScope.of(context);
    final Loan? loan = controller.loanById(loanId);
    if (loan == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.title),
        actions: <Widget>[
          IconButton(
            key: const Key('add-installment-button'),
            tooltip: 'قسط جدید',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddInstallmentScreen(loanId: loan.id),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) async {
              try {
                if (value == 'complete') {
                  await controller.completeLoan(loanId: loan.id);
                } else if (value == 'archive') {
                  await controller.archiveLoan(loanId: loan.id);
                }
              } on FinancialValidationException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (loan.remainingAmount.isZero &&
                  loan.status == LoanStatus.active)
                const PopupMenuItem<String>(
                  value: 'complete',
                  child: Text('تسویهٔ وام'),
                ),
              if (loan.status != LoanStatus.archived)
                const PopupMenuItem<String>(
                  value: 'archive',
                  child: Text('بایگانی'),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: <Widget>[
            _LoanHeader(loan: loan),
            const SizedBox(height: AppDimensions.spaceLg),
            Text(
              'قسط‌ها',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            if (loan.installments.isEmpty)
              _EmptyInstallments(loanId: loan.id)
            else
              for (final (int index, Installment installment)
                  in loan.installments.indexed)
                _InstallmentCard(
                  key: Key('installment-$index'),
                  index: index,
                  loan: loan,
                  installment: installment,
                ),
          ],
        ),
      ),
    );
  }
}

class _LoanHeader extends StatelessWidget {
  const _LoanHeader({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final int total = loan.totalPayable.minorUnits;
    final int paid = loan.paidAmount.minorUnits;
    final double progress = total == 0 ? 0 : (paid / total).clamp(0.0, 1.0);

    return PremiumCard(
      elevation: PremiumElevation.floating,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  loanStatusLabel(loan.status),
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (loan.lender.isNotEmpty)
                Text(
                  loan.lender,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: <Widget>[
              _HeaderMetric(label: 'کل بدهی', value: formatMinorUnits(total)),
              const Spacer(),
              _HeaderMetric(
                label: 'پرداخت‌شده',
                value: formatMinorUnits(paid),
                color: palette.positive,
              ),
              const Spacer(),
              _HeaderMetric(
                label: 'باقی‌مانده',
                value: formatMinorUnits(loan.remainingAmount.minorUnits),
                color: loan.remainingAmount.isZero
                    ? palette.positive
                    : palette.danger,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: palette.primary.withValues(alpha: 0.12),
              color: progress >= 1 ? palette.positive : palette.primary,
            ),
          ),
          if (loan.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              loan.notes,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    super.key,
    required this.index,
    required this.loan,
    required this.installment,
  });

  final int index;
  final Loan loan;
  final Installment installment;

  Color _statusColor(InstallmentStatus status, AppPalette palette) =>
      switch (status) {
        InstallmentStatus.paid => palette.positive,
        InstallmentStatus.partiallyPaid => palette.warning,
        InstallmentStatus.overdue => palette.danger,
        InstallmentStatus.cancelled => palette.textMuted,
        InstallmentStatus.rescheduled => palette.info,
        _ => palette.primary,
      };

  Future<void> _reschedule(BuildContext context, LoanController controller) async {
    final JalaliDate? picked = await showDialog<JalaliDate>(
      context: context,
      builder: (_) => _RescheduleDialog(
        initial: JalaliDate.fromDateTime(installment.dueDate),
      ),
    );
    if (picked == null) return;
    try {
      await controller.rescheduleInstallment(
        loanId: loan.id,
        installmentId: installment.id,
        newDueDate: picked.toGregorian(),
      );
    } on FinancialValidationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    LoanController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('لغو قسط'),
        content: const Text('این قسط لغو شود؟ پرداختی ندارد و از برنامه حذف نمی‌شود.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('لغو قسط'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.cancelInstallment(
        loanId: loan.id,
        installmentId: installment.id,
      );
    } on FinancialValidationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final InstallmentStatus status = installment.statusAt(DateTime.now());
    final Color statusColor = _statusColor(status, palette);
    final bool cancelled = installment.cancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: PremiumCard(
        elevation: PremiumElevation.flat,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'قسط ${toPersianDigits(installment.number)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Text(
                    installmentStatusLabel(status),
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'سررسید: ${formatJalaliDate(installment.dueDate)}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              children: <Widget>[
                _InstallmentMetric(
                  label: 'مبلغ',
                  value: formatMinorUnits(installment.totalAmount.minorUnits),
                ),
                const Spacer(),
                _InstallmentMetric(
                  label: 'پرداخت‌شده',
                  value: formatMinorUnits(installment.paidAmount.minorUnits),
                  color: palette.positive,
                ),
                const Spacer(),
                _InstallmentMetric(
                  label: 'باقی‌مانده',
                  value: formatMinorUnits(
                    installment.remainingAmount.minorUnits,
                  ),
                  color: installment.remainingAmount.isZero
                      ? palette.positive
                      : palette.danger,
                ),
              ],
            ),
            if (installment.rescheduled) ...<Widget>[
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                'با توافق تغییر کرده است.',
                style: TextStyle(color: palette.info, fontSize: 11),
              ),
            ],
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              children: <Widget>[
                FilledButton.tonalIcon(
                  key: Key('pay-$index'),
                  onPressed: cancelled
                      ? null
                      : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => _PaySheet(
                            loanId: loan.id,
                            installmentId: installment.id,
                            remaining: installment.remainingAmount,
                          ),
                        ),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('پرداخت'),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                IconButton(
                  key: Key('reschedule-$index'),
                  tooltip: 'تغییر سررسید',
                  onPressed: cancelled
                      ? null
                      : () => _reschedule(context, LoanScope.of(context)),
                  icon: const Icon(Icons.event_repeat_rounded),
                ),
                if (installment.paidAmount.isZero && !cancelled) ...<Widget>[
                  const SizedBox(width: AppDimensions.spaceXs),
                  IconButton(
                    key: Key('cancel-$index'),
                    tooltip: 'لغو قسط',
                    onPressed: () =>
                        _confirmCancel(context, LoanScope.of(context)),
                    icon: const Icon(Icons.block_rounded),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallmentMetric extends StatelessWidget {
  const _InstallmentMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyInstallments extends StatelessWidget {
  const _EmptyInstallments({required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.flat,
      child: Column(
        children: <Widget>[
          Icon(Icons.event_note_rounded, size: 44, color: palette.textMuted),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'هنوز قسطی ثبت نشده است',
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'با دکمهٔ بالا قسط اضافه کن.',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RescheduleDialog extends StatefulWidget {
  const _RescheduleDialog({required this.initial});

  final JalaliDate initial;

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late JalaliDate _date = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغییر سررسید'),
      content: JalaliDateField(
        value: _date,
        onChanged: (JalaliDate date) => setState(() => _date = date),
        label: 'سررسید جدید',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_date),
          child: const Text('ثبت'),
        ),
      ],
    );
  }
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({
    required this.loanId,
    required this.installmentId,
    required this.remaining,
  });

  final String loanId;
  final String installmentId;
  final Money remaining;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.remaining.minorUnits.toString(),
  );
  final TextEditingController _note = TextEditingController();
  String? _selectedAccount;
  JalaliDate _date = JalaliDate.today();
  String? _error;
  bool _busy = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final List<Account> accounts = AccountScope.of(context).accounts;
      if (accounts.length == 1) _selectedAccount = accounts.single.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final int? amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'مبلغ معتبر نیست.');
      return;
    }
    if (_selectedAccount == null) {
      setState(() => _error = 'ابتدا حساب پرداخت را انتخاب کنید.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await LoanScope.of(context).recordPayment(
        paymentId: 'pay-${DateTime.now().microsecondsSinceEpoch}',
        ledgerEntryId: 'ledger-${DateTime.now().microsecondsSinceEpoch}',
        loanId: widget.loanId,
        installmentId: widget.installmentId,
        accountId: _selectedAccount!,
        amount: Money(amount),
        paidDate: _date.toGregorian(),
        note: _note.text.trim(),
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
    final List<Account> accounts = AccountScope.of(context).accounts;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'پرداخت قسط',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            if (accounts.isEmpty)
              Text(
                'اول یک حساب بسازید تا پرداخت ثبت شود.',
                style: TextStyle(color: palette.warning),
              )
            else ...<Widget>[
              DropdownButtonFormField<String>(
                key: const Key('pay-account'),
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'حساب پرداخت',
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
                onChanged: accounts.length == 1
                    ? null
                    : (String? value) =>
                        setState(() => _selectedAccount = value),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('pay-amount'),
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
              const SizedBox(height: AppDimensions.spaceMd),
              JalaliDateField(
                value: _date,
                onChanged: (JalaliDate date) => setState(() => _date = date),
                label: 'تاریخ پرداخت',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextFormField(
                key: const Key('pay-note'),
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'یادداشت (اختیاری)',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                key: const Key('pay-submit'),
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.check_rounded),
                label: Text(_busy ? 'در حال ثبت...' : 'ثبت پرداخت'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

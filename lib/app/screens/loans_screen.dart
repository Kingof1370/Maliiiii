import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../state/loan_controller.dart';
import '../state/loan_format.dart';
import '../state/loan_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

/// مرکز وام‌ها و بدهی‌ها؛ فهرست واقعی از دفترکل با جزئیات هر وام.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoanController controller = LoanScope.of(context);
    final List<Loan> loans = controller.loans;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                FaStrings.loans,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filled(
                key: const Key('add-loan-button'),
                tooltip: 'وام جدید',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddLoanScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (loans.isEmpty)
            const _EmptyLoans()
          else ...<Widget>[
            _DebtSummary(controller: controller),
            const SizedBox(height: AppDimensions.spaceLg),
            for (final Loan loan in loans) _LoanCard(loan: loan),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _DebtSummary extends StatelessWidget {
  const _DebtSummary({required this.controller});

  final LoanController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      accent: palette.warning,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.warning.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.account_balance_rounded, color: palette.warning),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'بدهی باقی‌مانده',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                formatMinorUnits(controller.outstandingDebt.minorUnits),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${toPersianDigits(controller.activeLoans.length)} وام فعال',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});

  final Loan loan;

  Installment? get _nextDue {
    final List<Installment> unpaid = loan.installments
        .where((item) => item.remainingAmount.isPositive && !item.cancelled)
        .toList()
      ..sort((Installment a, Installment b) => a.dueDate.compareTo(b.dueDate));
    return unpaid.isEmpty ? null : unpaid.first;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final int total = loan.totalPayable.minorUnits;
    final int paid = loan.paidAmount.minorUnits;
    final int remaining = loan.remainingAmount.minorUnits;
    final double progress = total == 0 ? 0 : (paid / total).clamp(0.0, 1.0);
    final Installment? next = _nextDue;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: PremiumCard(
        elevation: PremiumElevation.raised,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LoanDetailScreen(loanId: loan.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    loan.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _StatusChip(label: loanStatusLabel(loan.status)),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            if (loan.lender.isNotEmpty)
              Text(
                loan.lender,
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: <Widget>[
                _Metric(label: 'کل بدهی', value: formatMinorUnits(total)),
                const SizedBox(width: AppDimensions.spaceLg),
                _Metric(
                  label: 'پرداخت‌شده',
                  value: formatMinorUnits(paid),
                  valueColor: palette.positive,
                ),
                const SizedBox(width: AppDimensions.spaceLg),
                _Metric(
                  label: 'باقی‌مانده',
                  value: formatMinorUnits(remaining),
                  valueColor: remaining > 0 ? palette.danger : palette.positive,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: palette.primary.withValues(alpha: 0.12),
                color: progress >= 1 ? palette.positive : palette.primary,
              ),
            ),
            if (next != null) ...<Widget>[
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                'قسط بعدی: ${formatJalaliDate(next.dueDate)} — '
                '${formatMinorUnits(next.remainingAmount.minorUnits)}',
                style: TextStyle(color: palette.warning, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
            color: valueColor ?? palette.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(color: palette.primary, fontSize: 12),
      ),
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.request_quote_rounded, size: 52, color: palette.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            FaStrings.noLoanYet,
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'با دکمهٔ بالا وام جدید ثبت کن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

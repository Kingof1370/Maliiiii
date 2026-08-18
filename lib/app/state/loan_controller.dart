import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import '../../src/money.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ وام‌ها؛ همهٔ تغییرات از طریق [LedgerController.commit] اجرا
/// و اتمیک پایدار می‌شوند تا دفترکل منبع حقیقت بماند.
///
/// یک وام می‌تواند ۱..N قسط داشته باشد؛ قسط‌ها نامنظم، جزئی، چندمرحله‌ای،
/// زودپرداخت، با تاریخ تغییر یافته و حتی چند قسط در یک روز مجازند.
final class LoanController extends ChangeNotifier {
  LoanController(this._ledger);

  final LedgerController _ledger;

  List<Loan> get loans => _ledger.ledger.loans;

  Money get outstandingDebt => _ledger.ledger.outstandingDebt();

  Money balanceOf(String accountId) => _ledger.ledger.accountBalance(accountId);

  List<Loan> get activeLoans =>
      loans.where((loan) => loan.status == LoanStatus.active).toList();

  Loan? loanById(String loanId) {
    for (final Loan loan in loans) {
      if (loan.id == loanId) return loan;
    }
    return null;
  }

  Future<Loan> createLoan({required Loan loan}) async {
    final FinancialLedger result = await _ledger.commit(
      (FinancialLedger current) => current.createLoan(loan: loan),
    );
    return result.loans.lastWhere((item) => item.id == loan.id);
  }

  Future<Installment> addInstallment({
    required String loanId,
    required Installment installment,
  }) async {
    await _ledger.commit(
      (FinancialLedger current) => current.addInstallment(
        loanId: loanId,
        installment: installment,
      ),
    );
    return loanById(loanId)!.installments
        .firstWhere((item) => item.id == installment.id);
  }

  Future<Installment> rescheduleInstallment({
    required String loanId,
    required String installmentId,
    required DateTime newDueDate,
  }) async {
    await _ledger.commit(
      (FinancialLedger current) => current.rescheduleInstallment(
        loanId: loanId,
        installmentId: installmentId,
        newDueDate: newDueDate,
      ),
    );
    return loanById(loanId)!.installments
        .firstWhere((item) => item.id == installmentId);
  }

  Future<Installment> cancelInstallment({
    required String loanId,
    required String installmentId,
  }) async {
    await _ledger.commit(
      (FinancialLedger current) => current.cancelInstallment(
        loanId: loanId,
        installmentId: installmentId,
      ),
    );
    return loanById(loanId)!.installments
        .firstWhere((item) => item.id == installmentId);
  }

  /// پرداخت (جزئی یا کامل) قسط از یک حساب واقعی؛ اعتبارسنجی در موتور: مبلغ
  /// بیش از باقی‌مانده یا موجودی ناکافی رد می‌شود و چیزی روی دیسک نمی‌رود.
  Future<PaymentReceipt> recordPayment({
    required String paymentId,
    required String ledgerEntryId,
    required String loanId,
    required String installmentId,
    required String accountId,
    required Money amount,
    required DateTime paidDate,
    String note = '',
  }) async {
    PaymentReceipt? receipt;
    await _ledger.commit((FinancialLedger current) {
      receipt = current.recordInstallmentPayment(
        paymentId: paymentId,
        ledgerEntryId: ledgerEntryId,
        loanId: loanId,
        installmentId: installmentId,
        accountId: accountId,
        amount: amount,
        paidDate: paidDate,
        note: note,
      );
      return receipt!.ledger;
    });
    return receipt!;
  }

  Future<void> completeLoan({required String loanId}) => _ledger.commit(
        (FinancialLedger current) => current.completeLoan(loanId: loanId),
      );

  Future<void> archiveLoan({required String loanId}) => _ledger.commit(
        (FinancialLedger current) => current.archiveLoan(loanId: loanId),
      );
}

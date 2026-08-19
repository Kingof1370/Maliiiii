import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import '../../src/money.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ حساب‌ها؛ همهٔ تغییرات از طریق [LedgerController.commit]
/// اجرا و پایدار می‌شوند تا دفترکل منبع حقیقت بماند.
final class AccountController extends ChangeNotifier {
  AccountController(this._ledger);

  final LedgerController _ledger;

  List<Account> get accounts => _ledger.ledger.accounts;

  /// موجودی واقعی حساب = موجودی اولیه + تراکنش‌های آن حساب.
  Money balanceOf(String accountId) => _ledger.ledger.accountBalance(accountId);

  Future<Account> addAccount({
    required String id,
    required String name,
    required AccountType type,
    required int openingMinorUnits,
    String? notes,
  }) async {
    final FinancialLedger result = await _ledger.commit(
      (FinancialLedger current) => current.createAccount(
        account: Account(
          id: id,
          name: name,
          type: type,
          openingBalance: Money(
            openingMinorUnits,
            currency: 'IRR',
          ),
          notes: notes ?? '',
        ),
      ),
    );
    return result.accounts.lastWhere((account) => account.id == id);
  }

  Future<FinancialLedger> recordIncome({
    required String id,
    required String accountId,
    required int amountMinorUnits,
    required DateTime date,
    String? category,
    String description = '',
  }) =>
      _ledger.commit(
        (FinancialLedger current) => current.recordIncome(
          id: id,
          accountId: accountId,
          amount: Money(amountMinorUnits, currency: 'IRR'),
          date: date,
          category: category,
          description: description,
        ),
      );

  Future<FinancialLedger> recordExpense({
    required String id,
    required String accountId,
    required int amountMinorUnits,
    required DateTime date,
    String? category,
    String description = '',
  }) =>
      _ledger.commit(
        (FinancialLedger current) => current.recordExpense(
          id: id,
          accountId: accountId,
          amount: Money(amountMinorUnits, currency: 'IRR'),
          date: date,
          category: category,
          description: description,
        ),
      );

  Future<FinancialLedger> recordTransfer({
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required DateTime date,
    String description = '',
  }) =>
      _ledger.commit(
        (FinancialLedger current) => current.recordTransfer(
          transferId: transferId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: Money(amountMinorUnits, currency: 'IRR'),
          date: date,
          description: description,
        ),
      );

  /// ویرایش تراکنش درجا؛ تغییرات از طریق [LedgerController.commit] پایدار می‌شوند.
  Future<FinancialLedger> updateTransaction({
    required String id,
    required String accountId,
    required int amountMinorUnits,
    required DateTime date,
    String? category,
    String? description,
  }) =>
      _ledger.commit(
        (FinancialLedger current) => current.updateTransaction(
          id: id,
          accountId: accountId,
          amount: Money(amountMinorUnits, currency: 'IRR'),
          date: date,
          category: category,
          description: description,
        ),
      );

  Future<FinancialLedger> deleteTransaction(String id) =>
      _ledger.commit((FinancialLedger current) => current.deleteTransaction(id));

  Future<FinancialLedger> updateAccount({
    required String id,
    String? name,
    AccountType? type,
    int? openingMinorUnits,
    String? notes,
  }) =>
      _ledger.commit(
        (FinancialLedger current) => current.updateAccount(
          id: id,
          name: name,
          type: type,
          openingBalance: openingMinorUnits == null
              ? null
              : Money(openingMinorUnits, currency: 'IRR'),
          notes: notes,
        ),
      );

  Future<FinancialLedger> deleteAccount(String id) =>
      _ledger.commit((FinancialLedger current) => current.deleteAccount(id));
}

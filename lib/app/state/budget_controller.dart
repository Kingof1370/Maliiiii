import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import '../../src/money.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ بودجه و تراکنش‌های تکرارشونده؛ همهٔ تغییرات از طریق
/// [LedgerController.commit] اجرا و اتمیک پایدار می‌شوند.
final class BudgetController extends ChangeNotifier {
  BudgetController(this._ledger);

  final LedgerController _ledger;

  List<Budget> get budgets => _ledger.ledger.budgets;
  List<RecurringTransaction> get recurrings => _ledger.ledger.recurrings;
  List<RecurringTransaction> get activeRecurrings =>
      recurrings.where((item) => item.active).toList();

  Money spentOf(Budget budget) => _ledger.ledger.budgetSpent(budget);

  Future<Budget> createBudget({required Budget budget}) async {
    final FinancialLedger result =
        await _ledger.commit((current) => current.createBudget(budget: budget));
    return result.budgets.lastWhere((item) => item.id == budget.id);
  }

  Future<void> deleteBudget({required String budgetId}) => _ledger.commit(
        (current) => current.deleteBudget(budgetId: budgetId),
      );

  Future<RecurringTransaction> createRecurring({
    required RecurringTransaction recurring,
  }) async {
    final FinancialLedger result = await _ledger.commit(
      (current) => current.createRecurring(recurring: recurring),
    );
    return result.recurrings.lastWhere((item) => item.id == recurring.id);
  }

  Future<void> toggleRecurring({
    required String recurringId,
    required bool active,
  }) =>
      _ledger.commit(
        (current) => current.toggleRecurring(
          recurringId: recurringId,
          active: active,
        ),
      );

  Future<void> deleteRecurring({required String recurringId}) =>
      _ledger.commit(
        (current) => current.deleteRecurring(recurringId: recurringId),
      );

  /// ثبت خودکار تراکنش‌های تکرارشوندهٔ سررسیدشده؛ تعداد تراکنش‌های جدید را
  /// برمی‌گرداند (۰ یعنی موردی برای ثبت نبود).
  Future<int> materializeDue({required DateTime asOf}) async {
    final int before = _ledger.ledger.transactions.length;
    await _ledger.commit(
      (current) => current.materializeDueRecurrings(asOf: asOf),
    );
    return _ledger.ledger.transactions.length - before;
  }
}

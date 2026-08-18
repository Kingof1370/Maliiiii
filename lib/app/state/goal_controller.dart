import 'package:flutter/foundation.dart';

import '../../src/engine.dart';
import '../../src/models.dart';
import '../../src/money.dart';
import 'ledger_controller.dart';

/// کنترل‌کنندهٔ اهداف مالی؛ همهٔ تغییرات از طریق [LedgerController.commit]
/// اجرا و اتمیک پایدار می‌شوند.
final class GoalController extends ChangeNotifier {
  GoalController(this._ledger);

  final LedgerController _ledger;

  List<Goal> get goals => _ledger.ledger.goals;

  Money get totalTarget =>
      goals.fold(const Money(0), (sum, item) => sum + item.target);

  Money get totalCurrent =>
      goals.fold(const Money(0), (sum, item) => sum + item.current);

  Money get reserved => _ledger.ledger.reservedForGoals();

  Future<Goal> createGoal({required Goal goal}) async {
    final FinancialLedger result =
        await _ledger.commit((current) => current.createGoal(goal: goal));
    return result.goals.lastWhere((item) => item.id == goal.id);
  }

  Future<void> contribute({
    required String goalId,
    required Money amount,
  }) =>
      _ledger.commit(
        (current) => current.contributeToGoal(goalId: goalId, amount: amount),
      );

  Future<void> deleteGoal({required String goalId}) => _ledger.commit(
        (current) => current.deleteGoal(goalId: goalId),
      );
}

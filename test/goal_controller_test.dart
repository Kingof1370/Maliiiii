import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/goal_controller.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';

void main() {
  late MemoryLedgerStore store;
  late LedgerController ledger;
  late GoalController goals;

  setUp(() async {
    store = MemoryLedgerStore();
    ledger = LedgerController(LedgerRepository(store));
    goals = GoalController(ledger);
    await ledger.init();
  });

  Goal sampleGoal(String id, {int target = 1_000_000}) => Goal(
        id: id,
        name: 'خرید خانه',
        type: GoalType.purchase,
        target: Money(target),
        current: const Money(0),
        deadline: DateTime(2028, 3, 20),
        priority: 4,
      );

  test('create goal persists and totals update', () async {
    await goals.createGoal(goal: sampleGoal('goal-1'));
    expect(store.ledger!.goals, hasLength(1));
    expect(goals.totalTarget.minorUnits, 1_000_000);
    expect(goals.reserved.minorUnits, 1_000_000);
  });

  test('contribute updates store and invalid over-target persists nothing',
      () async {
    await goals.createGoal(goal: sampleGoal('goal-1'));
    await goals.contribute(
      goalId: 'goal-1',
      amount: const Money(400_000),
    );
    expect(store.ledger!.goals.single.current.minorUnits, 400_000);
    expect(store.ledger!.goals.single.progress, closeTo(0.4, 1e-9));

    await expectLater(
      goals.contribute(
        goalId: 'goal-1',
        amount: const Money(999_999),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(store.ledger!.goals.single.current.minorUnits, 400_000);
  });

  test('delete goal removes it from the store', () async {
    await goals.createGoal(goal: sampleGoal('goal-1'));
    await goals.deleteGoal(goalId: 'goal-1');
    expect(store.ledger!.goals, isEmpty);
    await expectLater(
      goals.deleteGoal(goalId: 'missing'),
      throwsA(isA<FinancialValidationException>()),
    );
  });
}

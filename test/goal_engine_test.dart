import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  Goal goal({String id = 'g1', int target = 1000, int current = 0}) => Goal(
        id: id,
        name: 'سفر',
        type: GoalType.savings,
        target: Money(target),
        current: Money(current),
        deadline: DateTime(2027, 3, 20),
        priority: 3,
      );

  test('createGoal persists and rejects duplicates and zero target', () {
    const FinancialLedger ledger = FinancialLedger();
    final FinancialLedger withGoal = ledger.createGoal(goal: goal());
    expect(withGoal.goals, hasLength(1));
    expect(withGoal.reservedForGoals().minorUnits, 1000);

    expect(
      () => withGoal.createGoal(goal: goal()),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => ledger.createGoal(goal: goal(target: 0)),
      throwsA(isA<FinancialValidationException>()),
    );
  });

  test('contributeToGoal moves progress, frees reserve on completion', () {
    final FinancialLedger ledger = FinancialLedger(goals: <Goal>[goal()]);
    final FinancialLedger partial = ledger.contributeToGoal(
      goalId: 'g1',
      amount: const Money(400),
    );
    expect(partial.goals.single.current.minorUnits, 400);
    expect(partial.goals.single.progress, closeTo(0.4, 1e-9));
    expect(partial.reservedForGoals().minorUnits, 600);

    final FinancialLedger done = partial.contributeToGoal(
      goalId: 'g1',
      amount: const Money(600),
    );
    expect(done.goals.single.remaining.isZero, isTrue);
    expect(done.reservedForGoals().isZero, isTrue);
  });

  test('over-target and invalid contributions are rejected', () {
    final FinancialLedger ledger = FinancialLedger(goals: <Goal>[goal()]);
    expect(
      () => ledger.contributeToGoal(
        goalId: 'g1',
        amount: const Money(1001),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => ledger.contributeToGoal(
        goalId: 'g1',
        amount: const Money(-5),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => ledger.contributeToGoal(
        goalId: 'missing',
        amount: const Money(10),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
  });

  test('deleteGoal removes it and frees the reserve', () {
    final FinancialLedger ledger = FinancialLedger(goals: <Goal>[
      goal(),
      goal(id: 'g2', target: 500, current: 200),
    ]);
    expect(ledger.reservedForGoals().minorUnits, 1300);
    final FinancialLedger after = ledger.deleteGoal(goalId: 'g1');
    expect(after.goals, hasLength(1));
    expect(after.reservedForGoals().minorUnits, 300);
    expect(
      () => ledger.deleteGoal(goalId: 'missing'),
      throwsA(isA<FinancialValidationException>()),
    );
  });
}

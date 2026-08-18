import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/account_controller.dart';
import 'package:maliiiii/app/state/budget_controller.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';

void main() {
  late MemoryLedgerStore store;
  late LedgerController ledger;
  late BudgetController budgets;
  late AccountController accounts;

  setUp(() async {
    store = MemoryLedgerStore(
      FinancialLedger(accounts: <Account>[
        Account(
          id: 'acc-bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(10_000_000),
        ),
      ]),
    );
    ledger = LedgerController(LedgerRepository(store));
    budgets = BudgetController(ledger);
    accounts = AccountController(ledger);
    await ledger.init();
  });

  test('create budget persists and spentOf reflects category expenses',
      () async {
    await budgets.createBudget(
      budget: Budget(
        id: 'b1',
        name: 'خوراک ماهانه',
        amount: const Money(500_000),
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        category: 'خوراک',
      ),
    );
    expect(store.ledger!.budgets, hasLength(1));

    await accounts.recordExpense(
      id: 't1',
      accountId: 'acc-bank',
      amountMinorUnits: 120_000,
      date: DateTime(2026, 8, 10),
      category: 'خوراک',
    );
    await accounts.recordExpense(
      id: 't2',
      accountId: 'acc-bank',
      amountMinorUnits: 80_000,
      date: DateTime(2026, 8, 12),
      category: 'خرید',
    );
    expect(budgets.spentOf(store.ledger!.budgets.single).minorUnits, 120_000);
  });

  test('delete budget removes it', () async {
    await budgets.createBudget(
      budget: Budget(
        id: 'b1',
        name: 'مسکن',
        amount: const Money(2_000_000),
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      ),
    );
    await budgets.deleteBudget(budgetId: 'b1');
    expect(store.ledger!.budgets, isEmpty);
    await expectLater(
      budgets.deleteBudget(budgetId: 'missing'),
      throwsA(isA<FinancialValidationException>()),
    );
  });

  test('recurring create, materialize once, toggle, delete', () async {
    await budgets.createRecurring(
      recurring: RecurringTransaction(
        id: 'r1',
        name: 'حقوق',
        amount: const Money(100),
        kind: TransactionKind.income,
        accountId: 'acc-bank',
        frequency: RecurringFrequency.daily,
        startDate: DateTime(2026, 8, 1),
      ),
    );
    expect(store.ledger!.recurrings, hasLength(1));

    final int count =
        await budgets.materializeDue(asOf: DateTime(2026, 8, 5));
    expect(count, 5);
    expect(store.ledger!.transactions, hasLength(5));

    final int again = await budgets.materializeDue(asOf: DateTime(2026, 8, 5));
    expect(again, 0);
    expect(store.ledger!.transactions, hasLength(5));

    await budgets.toggleRecurring(recurringId: 'r1', active: false);
    expect(store.ledger!.recurrings.single.active, isFalse);
    expect(
      await budgets.materializeDue(asOf: DateTime(2026, 8, 9)),
      0,
    );

    await budgets.deleteRecurring(recurringId: 'r1');
    expect(store.ledger!.recurrings, isEmpty);
  });

  test('invalid inputs are rejected and nothing persists', () async {
    await expectLater(
      budgets.createBudget(
        budget: Budget(
          id: 'b',
          name: 'بد',
          amount: const Money(0),
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    await expectLater(
      budgets.createRecurring(
        recurring: RecurringTransaction(
          id: 'r',
          name: 'بد',
          amount: const Money(10),
          kind: TransactionKind.installmentPayment,
          accountId: 'acc-bank',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 8, 1),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(store.ledger!.budgets, isEmpty);
    expect(store.ledger!.recurrings, isEmpty);
  });
}

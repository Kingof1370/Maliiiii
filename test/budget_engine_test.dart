import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  final Account account = Account(
    id: 'a',
    name: 'نقدی',
    type: AccountType.cash,
    openingBalance: const Money(0),
  );

  test('budgetSpent matches category and period and excludes installments',
      () {
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[account],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 't1',
          accountId: 'a',
          amount: const Money(100),
          date: DateTime(2026, 8, 5),
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
        LedgerTransaction(
          id: 't2',
          accountId: 'a',
          amount: const Money(50),
          date: DateTime(2026, 8, 10),
          kind: TransactionKind.expense,
          category: 'خرید',
        ),
        LedgerTransaction(
          id: 't3',
          accountId: 'a',
          amount: const Money(30),
          date: DateTime(2026, 9, 1),
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
        LedgerTransaction(
          id: 't4',
          accountId: 'a',
          amount: const Money(200),
          date: DateTime(2026, 8, 8),
          kind: TransactionKind.installmentPayment,
        ),
      ],
    );
    final Budget food = Budget(
      id: 'b1',
      name: 'خوراک',
      amount: const Money(500),
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      category: 'خوراک',
    );
    expect(ledger.budgetSpent(food).minorUnits, 100);

    final Budget all = Budget(
      id: 'b2',
      name: 'همه',
      amount: const Money(1000),
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
    );
    // بدون قسط: ۱۰۰ + ۵۰ = ۱۵۰
    expect(ledger.budgetSpent(all).minorUnits, 150);
  });

  test('createBudget rejects zero amount and reversed dates', () {
    const FinancialLedger ledger = FinancialLedger();
    expect(
      () => ledger.createBudget(
        budget: Budget(
          id: 'b',
          name: 'x',
          amount: const Money(0),
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => ledger.createBudget(
        budget: Budget(
          id: 'b',
          name: 'x',
          amount: const Money(100),
          startDate: DateTime(2026, 8, 31),
          endDate: DateTime(2026, 8, 1),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
  });

  test('materializeDueRecurrings generates only due transactions once', () {
    final RecurringTransaction recurring = RecurringTransaction(
      id: 'r1',
      name: 'اجاره',
      amount: const Money(100),
      kind: TransactionKind.expense,
      accountId: 'a',
      frequency: RecurringFrequency.daily,
      startDate: DateTime(2026, 8, 1),
    );
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[account],
      recurrings: <RecurringTransaction>[recurring],
    );
    final FinancialLedger after =
        ledger.materializeDueRecurrings(asOf: DateTime(2026, 8, 3));
    expect(after.transactions, hasLength(3));
    expect(after.recurrings.single.lastGenerated, DateTime(2026, 8, 3));

    final FinancialLedger again =
        after.materializeDueRecurrings(asOf: DateTime(2026, 8, 3));
    expect(again.transactions, hasLength(3));
  });

  test('endDate and inactive stop generation; monthly respects month end',
      () {
    final RecurringTransaction ended = RecurringTransaction(
      id: 'r2',
      name: 'قبض',
      amount: const Money(50),
      kind: TransactionKind.expense,
      accountId: 'a',
      frequency: RecurringFrequency.daily,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 2),
    );
    final FinancialLedger endedLedger = FinancialLedger(
      accounts: <Account>[account],
      recurrings: <RecurringTransaction>[ended],
    );
    final FinancialLedger afterEnd =
        endedLedger.materializeDueRecurrings(asOf: DateTime(2026, 8, 5));
    expect(afterEnd.transactions, hasLength(2));

    final RecurringTransaction inactive = RecurringTransaction(
      id: 'r3',
      name: 'خاموش',
      amount: const Money(10),
      kind: TransactionKind.expense,
      accountId: 'a',
      frequency: RecurringFrequency.daily,
      startDate: DateTime(2026, 8, 1),
      active: false,
    );
    final FinancialLedger inactiveLedger = FinancialLedger(
      accounts: <Account>[account],
      recurrings: <RecurringTransaction>[inactive],
    );
    expect(
      inactiveLedger
          .materializeDueRecurrings(asOf: DateTime(2026, 8, 5))
          .transactions,
      isEmpty,
    );

    // ۳۱ بهمن → ۲۸ اسفند (سال ۲۰۲۶ میلادی کبیسه نیست).
    final RecurringTransaction monthly = RecurringTransaction(
      id: 'r4',
      name: 'ماهانه',
      amount: const Money(20),
      kind: TransactionKind.expense,
      accountId: 'a',
      frequency: RecurringFrequency.monthly,
      startDate: DateTime(2026, 1, 31),
    );
    final FinancialLedger monthlyLedger = FinancialLedger(
      accounts: <Account>[account],
      recurrings: <RecurringTransaction>[monthly],
    );
    // asOf باید خودِ ۲۸ بهمن باشد تا قسط دوم (۲۸ بهمن) هم سررسیدشده شمرده شود.
    final FinancialLedger afterMonthly =
        monthlyLedger.materializeDueRecurrings(asOf: DateTime(2026, 2, 28));
    expect(afterMonthly.transactions, hasLength(2));
    expect(afterMonthly.transactions[1].date, DateTime(2026, 2, 28));
  });

  test('createRecurring rejects transfer kind and unknown account', () {
    final FinancialLedger ledger =
        FinancialLedger(accounts: <Account>[account]);
    expect(
      () => ledger.createRecurring(
        recurring: RecurringTransaction(
          id: 'r',
          name: 'x',
          amount: const Money(10),
          kind: TransactionKind.transferIn,
          accountId: 'a',
          frequency: RecurringFrequency.daily,
          startDate: DateTime(2026, 8, 1),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    expect(
      () => ledger.createRecurring(
        recurring: RecurringTransaction(
          id: 'r',
          name: 'x',
          amount: const Money(10),
          kind: TransactionKind.expense,
          accountId: 'missing',
          frequency: RecurringFrequency.daily,
          startDate: DateTime(2026, 8, 1),
        ),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
  });
}

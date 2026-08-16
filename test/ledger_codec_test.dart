import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  Money rial(int amount) => Money(amount, currency: 'IRR');

  test('money json round-trip preserves minor units and currency', () {
    const Money original = Money(1234567, currency: 'IRR');
    final Money restored = Money.fromJson(original.toJson());
    expect(restored, original);
    expect(restored.minorUnits, 1234567);
    expect(restored.currency, 'IRR');
  });

  test('account json round-trip keeps all fields', () {
    final Account original = Account(
      id: 'bank',
      name: 'بانک ملی',
      type: AccountType.bank,
      openingBalance: rial(1000000),
      notes: 'حساب اصلی',
    );
    final Account restored = Account.fromJson(original.toJson());
    expect(restored.id, 'bank');
    expect(restored.name, 'بانک ملی');
    expect(restored.type, AccountType.bank);
    expect(restored.openingBalance, rial(1000000));
    expect(restored.notes, 'حساب اصلی');
  });

  test('transaction json round-trip for every kind', () {
    for (final TransactionKind kind in TransactionKind.values) {
      final LedgerTransaction original = LedgerTransaction(
        id: 'tx-${kind.name}',
        accountId: 'bank',
        amount: rial(50000),
        date: DateTime(2026, 8, 10, 15, 30),
        kind: kind,
        category: 'خوراک',
        description: 'توضیح فارسی',
        referenceId: kind == TransactionKind.installmentPayment ? 'i1' : null,
        transferId:
            kind == TransactionKind.transferOut || kind == TransactionKind.transferIn
                ? 'tr1'
                : null,
      );
      final LedgerTransaction restored =
          LedgerTransaction.fromJson(original.toJson());
      expect(restored.kind, kind);
      expect(restored.amount, rial(50000));
      expect(restored.category, 'خوراک');
      expect(restored.date, DateTime(2026, 8, 10, 15, 30));
      expect(restored.transferId, original.transferId);
      expect(restored.referenceId, original.referenceId);
    }
  });

  test('payment and installment round-trip with partial payments', () {
    final Installment original = Installment(
      id: 'i1',
      loanId: 'loan1',
      number: 3,
      dueDate: DateTime(2026, 9, 5),
      totalAmount: rial(20000000),
      principal: rial(16000000),
      interest: rial(4000000),
      fee: null,
      payments: <Payment>[
        Payment(
          id: 'p1',
          amount: rial(5000000),
          paidDate: DateTime(2026, 8, 30),
          accountId: 'bank',
          note: 'پرداخت اول',
        ),
        Payment(
          id: 'p2',
          amount: rial(7000000),
          paidDate: DateTime(2026, 9, 1),
          accountId: 'cash',
        ),
      ],
      cancelled: false,
      rescheduled: true,
      notes: 'زودتر پرداخت شد',
    );
    final Installment restored = Installment.fromJson(original.toJson());
    expect(restored.number, 3);
    expect(restored.payments, hasLength(2));
    expect(restored.paidAmount, rial(12000000));
    expect(restored.remainingAmount, rial(8000000));
    expect(restored.rescheduled, isTrue);
    expect(restored.principal, rial(16000000));
    expect(restored.fee, isNull);
    // پرچم rescheduled در همان قسط true است؛ پس وضعیت rescheduled است نه partiallyPaid
    expect(restored.statusAt(DateTime(2026, 9, 2)), InstallmentStatus.rescheduled);
  });

  test('loan round-trip keeps installments and derived numbers', () {
    final Loan original = Loan(
      id: 'loan1',
      title: 'وام خودرو',
      lender: 'بانک ملی',
      principal: rial(60000000),
      receivedAmount: rial(60000000),
      interest: rial(12000000),
      fees: rial(0),
      totalPayable: rial(72000000),
      startDate: DateTime(2026, 7, 1),
      notes: 'قسط‌های متغیر',
      installments: <Installment>[
        Installment(
          id: 'i1',
          loanId: 'loan1',
          number: 1,
          dueDate: DateTime(2026, 8, 10),
          totalAmount: rial(12000000),
        ),
      ],
    );
    final Loan restored = Loan.fromJson(original.toJson());
    expect(restored.title, 'وام خودرو');
    expect(restored.lender, 'بانک ملی');
    expect(restored.totalPayable, rial(72000000));
    expect(restored.installments.single.id, 'i1');
    expect(restored.paidAmount, rial(0));
    expect(restored.remainingAmount, rial(72000000));
  });

  test('budget and goal json round-trip', () {
    final Budget budget = Budget(
      id: 'b1',
      name: 'خوراک',
      amount: rial(3000000),
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      category: 'خوراک',
    );
    final Budget restoredBudget = Budget.fromJson(budget.toJson());
    expect(restoredBudget.name, 'خوراک');
    expect(restoredBudget.amount, rial(3000000));

    final Goal goal = Goal(
      id: 'g1',
      name: 'پس‌انداز سفر',
      type: GoalType.savings,
      target: rial(50000000),
      current: rial(12000000),
      deadline: DateTime(2027, 3, 20),
      priority: 2,
    );
    final Goal restoredGoal = Goal.fromJson(goal.toJson());
    expect(restoredGoal.type, GoalType.savings);
    expect(restoredGoal.progress, closeTo(0.24, 0.001));
    expect(restoredGoal.priority, 2);
  });

  test('full ledger round-trip with persian data', () {
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: rial(1000000),
        ),
        Account(
          id: 'cash',
          name: 'نقدی',
          type: AccountType.cash,
          openingBalance: rial(0),
        ),
      ],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'inc1',
          accountId: 'bank',
          amount: rial(5000000),
          date: DateTime(2026, 8, 1),
          kind: TransactionKind.income,
          category: 'حقوق',
          description: 'حقوق مرداد',
        ),
        LedgerTransaction(
          id: 'exp1',
          accountId: 'bank',
          amount: rial(800000),
          date: DateTime(2026, 8, 3),
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
        LedgerTransaction(
          id: 'tr:out',
          accountId: 'bank',
          amount: rial(200000),
          date: DateTime(2026, 8, 4),
          kind: TransactionKind.transferOut,
          transferId: 'tr1',
        ),
        LedgerTransaction(
          id: 'tr:in',
          accountId: 'cash',
          amount: rial(200000),
          date: DateTime(2026, 8, 4),
          kind: TransactionKind.transferIn,
          transferId: 'tr1',
        ),
      ],
      loans: <Loan>[
        Loan(
          id: 'loan1',
          title: 'وام خودرو',
          lender: 'بانک ملی',
          principal: rial(60000000),
          receivedAmount: rial(60000000),
          interest: rial(12000000),
          fees: rial(0),
          totalPayable: rial(72000000),
          startDate: DateTime(2026, 7, 1),
          installments: <Installment>[
            Installment(
              id: 'i1',
              loanId: 'loan1',
              number: 1,
              dueDate: DateTime(2026, 8, 10),
              totalAmount: rial(12000000),
              principal: rial(10000000),
              interest: rial(2000000),
              payments: <Payment>[
                Payment(
                  id: 'p1',
                  amount: rial(5000000),
                  paidDate: DateTime(2026, 8, 8),
                  accountId: 'bank',
                  note: 'قسط اول',
                ),
              ],
            ),
            Installment(
              id: 'i2',
              loanId: 'loan1',
              number: 2,
              dueDate: DateTime(2026, 9, 10),
              totalAmount: rial(12000000),
            ),
          ],
        ),
      ],
      budgets: <Budget>[
        Budget(
          id: 'b1',
          name: 'خوراک',
          amount: rial(3000000),
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
          category: 'خوراک',
        ),
      ],
      goals: <Goal>[
        Goal(
          id: 'g1',
          name: 'پس‌انداز سفر',
          type: GoalType.savings,
          target: rial(50000000),
          current: rial(12000000),
          deadline: DateTime(2027, 3, 20),
          priority: 2,
        ),
      ],
    );

    final FinancialLedger restored = FinancialLedger.fromJson(ledger.toJson());

    expect(restored.accounts, hasLength(2));
    expect(restored.accounts[0].name, 'بانک');
    expect(restored.transactions, hasLength(4));
    expect(restored.transactions.first.category, 'حقوق');
    expect(restored.transactions[2].transferId, 'tr1');
    expect(restored.loans.single.installments, hasLength(2));
    final Installment paid = restored.loans.single.installments.first;
    expect(paid.payments.single.amount, rial(5000000));
    expect(paid.remainingAmount, rial(7000000));
    expect(paid.statusAt(DateTime(2026, 8, 9)),
        InstallmentStatus.partiallyPaid);
    expect(restored.budgets.single.category, 'خوراک');
    expect(restored.goals.single.progress, closeTo(0.24, 0.001));
    expect(restored.totalBalance(), rial(5200000));
  });

  test('ledger rejects unsupported schema version', () {
    expect(
      () => FinancialLedger.fromJson(<String, Object?>{'schemaVersion': 99}),
      throwsFormatException,
    );
  });

  test('ledger tolerates missing fields with safe defaults', () {
    final FinancialLedger restored =
        FinancialLedger.fromJson(<String, Object?>{'schemaVersion': 1});
    expect(restored.accounts, isEmpty);
    expect(restored.loans, isEmpty);
    expect(restored.totalBalance(), const Money(0));
  });
}

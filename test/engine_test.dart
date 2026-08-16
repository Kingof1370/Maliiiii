import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  final today = DateTime(2026, 8, 16);
  final rial = (int amount) => Money(amount, currency: 'IRR');
  final accounts = [
    Account(
      id: 'bank',
      name: 'بانک',
      type: AccountType.bank,
      openingBalance: rial(1000),
    ),
    Account(
      id: 'cash',
      name: 'نقدی',
      type: AccountType.cash,
      openingBalance: rial(0),
    ),
  ];

  test('money arithmetic is integer and currency-safe', () {
    expect(rial(100) + rial(25), equals(rial(125)));
    expect(rial(100) - rial(25), equals(rial(75)));
    expect(() => rial(1).compareTo(const Money(1, currency: 'USD')),
        throwsArgumentError);
  });

  test('transfer changes account balances but not net worth', () {
    const ledger = FinancialLedger(accounts: [
      Account(
        id: 'bank',
        name: 'بانک',
        type: AccountType.bank,
        openingBalance: Money(1000),
      ),
      Account(
        id: 'cash',
        name: 'نقدی',
        type: AccountType.cash,
        openingBalance: Money(0),
      ),
    ]);
    final updated = ledger.recordTransfer(
      transferId: 't1',
      fromAccountId: 'bank',
      toAccountId: 'cash',
      amount: Money(400),
      date: today,
    );
    expect(updated.accountBalance('bank'), equals(const Money(600)));
    expect(updated.accountBalance('cash'), equals(const Money(400)));
    expect(updated.totalBalance(), equals(const Money(1000)));
    expect(updated.monthlySummary(today).expense, equals(const Money(0)));
  });

  test('automatic installment schedule supports variable amounts', () {
    final loan = Loan(
      id: 'loan',
      title: 'وام خودرو',
      lender: 'بانک',
      principal: rial(600),
      receivedAmount: rial(600),
      interest: rial(60),
      fees: rial(0),
      totalPayable: rial(660),
      startDate: today,
      installments: [
        Installment(
          id: 'i1',
          loanId: 'loan',
          number: 1,
          dueDate: DateTime(2026, 9, 10),
          totalAmount: rial(100),
        ),
        Installment(
          id: 'i2',
          loanId: 'loan',
          number: 2,
          dueDate: DateTime(2026, 10, 15),
          totalAmount: rial(200),
        ),
        Installment(
          id: 'i3',
          loanId: 'loan',
          number: 3,
          dueDate: DateTime(2026, 11, 20),
          totalAmount: rial(360),
        ),
      ],
    );
    expect(loan.installments, hasLength(3));
    expect(loan.installments[1].totalAmount, equals(rial(200)));
    expect(loan.remainingAmount, equals(rial(660)));
  });

  test('partial and multiple installment payments are ledger-safe', () {
    final loan = Loan(
      id: 'loan',
      title: 'وام شخصی',
      lender: 'بانک',
      principal: rial(1000),
      receivedAmount: rial(1000),
      interest: rial(0),
      fees: rial(0),
      totalPayable: rial(1000),
      startDate: today,
      installments: [
        Installment(
          id: 'i1',
          loanId: 'loan',
          number: 1,
          dueDate: DateTime(2026, 8, 20),
          totalAmount: rial(500),
        ),
      ],
    );
    var ledger = FinancialLedger(accounts: accounts, loans: [loan]);
    final first = ledger.recordInstallmentPayment(
      paymentId: 'p1',
      ledgerEntryId: 'entry1',
      loanId: 'loan',
      installmentId: 'i1',
      accountId: 'bank',
      amount: rial(200),
      paidDate: today,
    );
    ledger = first.ledger;
    expect(first.installment.statusAt(today), InstallmentStatus.partiallyPaid);
    expect(first.installment.remainingAmount, equals(rial(300)));
    final second = ledger.recordInstallmentPayment(
      paymentId: 'p2',
      ledgerEntryId: 'entry2',
      loanId: 'loan',
      installmentId: 'i1',
      accountId: 'bank',
      amount: rial(300),
      paidDate: DateTime(2026, 8, 17),
    );
    expect(second.installment.statusAt(today), InstallmentStatus.paid);
    expect(second.loan.paidAmount, equals(rial(500)));
    expect(second.ledger.monthlySummary(today).expense, equals(rial(0)));
    expect(
      second.ledger.monthlySummary(today).installmentPayments,
      equals(rial(500)),
    );
    expect(() => second.ledger.recordInstallmentPayment(
          paymentId: 'p3',
          ledgerEntryId: 'entry3',
          loanId: 'loan',
          installmentId: 'i1',
          accountId: 'bank',
          amount: rial(1),
          paidDate: today,
        ), throwsA(isA<FinancialValidationException>()));
  });

  test('available money reserves near installments, budgets and goals', () {
    final ledger = FinancialLedger(
      accounts: accounts,
      loans: [
        Loan(
          id: 'loan',
          title: 'وام',
          lender: 'بانک',
          principal: rial(100),
          receivedAmount: rial(100),
          interest: rial(0),
          fees: rial(0),
          totalPayable: rial(100),
          startDate: today,
          installments: [
            Installment(
              id: 'i1',
              loanId: 'loan',
              number: 1,
              dueDate: DateTime(2026, 8, 20),
              totalAmount: rial(100),
            ),
          ],
        ),
      ],
      budgets: [
        Budget(
          id: 'budget',
          name: 'ضروری',
          amount: rial(100),
          startDate: DateTime(2026, 8),
          endDate: DateTime(2026, 9),
        ),
      ],
      goals: [
        Goal(
          id: 'goal',
          name: 'پس‌انداز',
          type: GoalType.savings,
          target: rial(100),
          current: rial(25),
          deadline: DateTime(2027),
        ),
      ],
    );
    expect(ledger.availableMoney(asOf: today), equals(rial(725)));
  });

  test('forecast refuses empty history and computes from real entries', () {
    const empty = FinancialLedger();
    expect(
      empty.forecast(
        asOf: DateTime(2026, 8, 16),
        periodEnd: DateTime(2026, 8, 31),
      ),
      isNull,
    );
    final ledger = FinancialLedger(
      accounts: accounts,
      transactions: [
        for (var day = 0; day < 30; day++)
          LedgerTransaction(
            id: 'income-$day',
            accountId: 'bank',
            amount: Money(100),
            date: DateTime(2026, 7, 18).add(Duration(days: day)),
            kind: TransactionKind.income,
          ),
      ],
    );
    final result = ledger.forecast(
      asOf: today,
      periodEnd: DateTime(2026, 8, 31),
    );
    expect(result, isNotNull);
    expect(result!.expectedIncome, equals(Money(495)));
    expect(result.sampleDays, 91);
  });

  test('health score exposes documented inputs', () {
    final ledger = FinancialLedger(
      accounts: accounts,
      transactions: [
        LedgerTransaction(
          id: 'income',
          accountId: 'bank',
          amount: rial(1000),
          date: today,
          kind: TransactionKind.income,
        ),
        LedgerTransaction(
          id: 'expense',
          accountId: 'bank',
          amount: rial(200),
          date: today,
          kind: TransactionKind.expense,
        ),
      ],
    );
    final score = ledger.healthScore(today);
    expect(score.value, inInclusiveRange(0, 100));
    expect(score.explanation, contains('۳۰٪'));
    expect(score.savingsRate, closeTo(0.8, 0.001));
  });
}
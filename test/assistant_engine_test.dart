import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  final DateTime now = DateTime(2026, 8, 19);

  FinancialLedger baseLedger() => FinancialLedger(
        accounts: <Account>[
          Account(
            id: 'cash',
            name: 'نقدی',
            type: AccountType.cash,
            openingBalance: const Money(1_000_000),
          ),
        ],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'i1',
            accountId: 'cash',
            amount: const Money(2_000_000),
            date: DateTime(2026, 8, 5),
            kind: TransactionKind.income,
            category: 'حقوق',
          ),
          LedgerTransaction(
            id: 'e1',
            accountId: 'cash',
            amount: const Money(800_000),
            date: DateTime(2026, 8, 10),
            kind: TransactionKind.expense,
            category: 'خوراک',
          ),
        ],
      );

  List<Insight> insightsOf(FinancialLedger ledger) =>
      buildInsights(ledger, asOf: now);

  Insight? byTitle(List<Insight> insights, String title) {
    for (final Insight insight in insights) {
      if (insight.title == title) return insight;
    }
    return null;
  }

  test('returns no insights for an empty ledger', () {
    expect(insightsOf(const FinancialLedger()), isEmpty);
  });

  test('produces overview, health and top-category insights', () {
    final List<Insight> insights = insightsOf(baseLedger());
    final Insight? overview = byTitle(insights, 'نمای کلی');
    expect(overview, isNotNull);
    expect(overview!.body, contains('تومان'));
    expect(byTitle(insights, 'امتیاز سلامت مالی'), isNotNull);
    final Insight? top = byTitle(insights, 'بزرگ‌ترین دستهٔ هزینه');
    expect(top, isNotNull);
    expect(top!.body, contains('خوراک'));
  });

  test('flags an overspent budget', () {
    final FinancialLedger ledger = baseLedger().copyWith(
      budgets: <Budget>[
        Budget(
          id: 'b1',
          name: 'خوراک ماه',
          amount: const Money(500_000),
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
          category: 'خوراک',
        ),
      ],
    );
    final Insight? budget = byTitle(insightsOf(ledger), 'بودجهٔ ردشده');
    expect(budget, isNotNull);
    expect(budget!.body, contains('خوراک ماه'));
  });

  test('warns about overdue installments', () {
    final Loan loan = Loan(
      id: 'l1',
      title: 'وام بانک',
      lender: 'بانک ملی',
      principal: const Money(1_000_000),
      receivedAmount: const Money(1_000_000),
      interest: const Money(0),
      fees: const Money(0),
      totalPayable: const Money(600_000),
      startDate: DateTime(2026, 7, 1),
      installments: <Installment>[
        Installment(
          id: 'ins1',
          loanId: 'l1',
          number: 1,
          dueDate: DateTime(2026, 8, 15),
          totalAmount: const Money(300_000),
        ),
        Installment(
          id: 'ins2',
          loanId: 'l1',
          number: 2,
          dueDate: DateTime(2026, 8, 28),
          totalAmount: const Money(300_000),
        ),
      ],
    );
    final FinancialLedger ledger = baseLedger().copyWith(loans: <Loan>[loan]);
    final Insight? overdue = byTitle(insightsOf(ledger), 'قسط معوق دارید');
    expect(overdue, isNotNull);
    expect(overdue!.body, contains('قسط'));
  });

  test('warns about a goal close to deadline with low progress', () {
    final FinancialLedger ledger = baseLedger().copyWith(
      goals: <Goal>[
        Goal(
          id: 'g1',
          name: 'ماشین',
          type: GoalType.purchase,
          target: const Money(10_000_000),
          current: const Money(1_000_000),
          deadline: DateTime(2026, 9, 10),
        ),
      ],
    );
    final Insight? goal = byTitle(insightsOf(ledger), 'هدف در خطر');
    expect(goal, isNotNull);
    expect(goal!.body, contains('ماشین'));
  });

  test('reports negative total balance with highest priority', () {
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'cash',
          name: 'نقدی',
          type: AccountType.cash,
          openingBalance: Money(-200_000),
        ),
      ],
    );
    final List<Insight> insights = insightsOf(ledger);
    expect(insights, isNotEmpty);
    expect(insights.first.title, 'موجودی منفی');
  });
}

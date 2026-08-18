import 'package:maliiiii/app/state/report_data.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  final FinancialLedger ledger = FinancialLedger(
    accounts: <Account>[
      Account(
        id: 'a',
        name: 'نقدی',
        type: AccountType.cash,
        openingBalance: const Money(0),
      ),
    ],
    transactions: <LedgerTransaction>[
      LedgerTransaction(
        id: 't1',
        accountId: 'a',
        amount: const Money(2_000_000),
        date: DateTime(2026, 8, 5),
        kind: TransactionKind.income,
        category: 'حقوق',
      ),
      LedgerTransaction(
        id: 't2',
        accountId: 'a',
        amount: const Money(600_000),
        date: DateTime(2026, 8, 10),
        kind: TransactionKind.expense,
        category: 'خوراک',
      ),
      LedgerTransaction(
        id: 't3',
        accountId: 'a',
        amount: const Money(200_000),
        date: DateTime(2026, 8, 12),
        kind: TransactionKind.expense,
        category: 'خرید',
      ),
      // خارج از بازهٔ مرداد ۱۴۰۵ (اول مرداد = ۲۳ ژوئیهٔ ۲۰۲۶)
      LedgerTransaction(
        id: 't4',
        accountId: 'a',
        amount: const Money(500_000),
        date: DateTime(2026, 7, 1),
        kind: TransactionKind.expense,
        category: 'قبض',
      ),
    ],
  );

  test('buildJalaliMonthReport scopes to the Persian month', () {
    final JalaliMonthReport report =
        buildJalaliMonthReport(ledger, const JalaliDate(1405, 5, 1));
    expect(report.income.minorUnits, 2_000_000);
    expect(report.expense.minorUnits, 800_000);
    expect(report.installments.minorUnits, 0);
    expect(report.cashflow.minorUnits, 1_200_000);
  });

  test('categoryBreakdown groups and sorts descending by amount', () {
    final List<CategorySlice> slices =
        categoryBreakdown(ledger, DateTime(2026, 7, 23), DateTime(2026, 8, 23));
    expect(slices, hasLength(2));
    expect(slices.first.category, 'خوراک');
    expect(slices.first.amount.minorUnits, 600_000);
    expect(slices.last.amount.minorUnits, 200_000);
  });

  test('buildTextReport contains persian lines', () {
    final JalaliMonthReport report =
        buildJalaliMonthReport(ledger, const JalaliDate(1405, 5, 1));
    final String text = buildTextReport(
      report: report,
      month: const JalaliDate(1405, 5, 1),
      healthScore: 75,
    );
    expect(text, contains('گزارش مالی — مرداد ۱۴۰۵'));
    expect(text, contains('درآمد: ۲,۰۰۰,۰۰۰ تومان'));
    expect(text, contains('هزینه: ۸۰۰,۰۰۰ تومان'));
    expect(text, contains('امتیاز سلامت مالی: ۷۵ از ۱۰۰'));
  });

  test('fraction clamps and handles zero total', () {
    const CategorySlice slice = CategorySlice(
      category: 'خوراک',
      amount: Money(500),
    );
    expect(slice.fraction(1000), closeTo(0.5, 1e-9));
    expect(slice.fraction(0), 0);
    expect(slice.fraction(-1), 0);
  });
}

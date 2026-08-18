import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/reports_screen.dart';
import 'package:maliiiii/main.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

UserProfile seededProfile() =>
    UserProfile.create(firstName: 'علی', lastName: 'بهمنی');

Future<void> pumpApp(
  WidgetTester tester,
  ProfileStore store, {
  MemoryLedgerStore? ledger,
}) async {
  await tester.pumpWidget(
    MaliiiiiApp(profileStore: store, ledgerStore: ledger ?? MemoryLedgerStore()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reports show real numbers from the ledger',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore(
      FinancialLedger(accounts: <Account>[
        Account(
          id: 'a',
          name: 'نقدی',
          type: AccountType.cash,
          openingBalance: const Money(0),
        ),
      ], transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 't1',
          accountId: 'a',
          amount: const Money(2_000_000),
          date: DateTime(2026, 8, 5),
          kind: TransactionKind.income,
        ),
        LedgerTransaction(
          id: 't2',
          accountId: 'a',
          amount: const Money(800_000),
          date: DateTime(2026, 8, 10),
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
      ]),
    );
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('گزارش‌ها'));
    await tester.pumpAndSettle();

    expect(find.textContaining('۲,۰۰۰,۰۰۰'), findsWidgets);
    expect(find.textContaining('۸۰۰,۰۰۰'), findsWidgets);
    expect(find.text('امتیاز سلامت مالی'), findsOneWidget);
    expect(find.byKey(const Key('report-forecast-card')), findsOneWidget);

    await scrollToIn(
      tester,
      find.textContaining('گزارش متنی'),
      ReportsScreen,
    );
    expect(find.textContaining('گزارش متنی'), findsOneWidget);
    expect(find.textContaining('درآمد: ۲,۰۰۰,۰۰۰ تومان'), findsOneWidget);
  });

  testWidgets('empty ledger shows the empty report state',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore();
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('گزارش‌ها'));
    await tester.pumpAndSettle();

    expect(find.text('هنوز داده‌ای برای گزارش نیست'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/add_budget_screen.dart';
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
  testWidgets('add budget via UI persists and shows in list',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore();
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('بودجه'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز بودجه‌ای ثبت نشده است'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-budget-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('budget-name')), 'بودجه خوراک');
    await tester.enterText(find.byKey(const Key('budget-amount')), '500000');

    await scrollToIn(
      tester,
      find.byKey(const Key('budget-save')),
      AddBudgetScreen,
    );
    await tester.tap(find.byKey(const Key('budget-save')));
    await tester.pumpAndSettle();

    expect(ledger.ledger!.budgets, hasLength(1));
    expect(ledger.ledger!.budgets.single.name, 'بودجه خوراک');
    expect(find.text('بودجه خوراک'), findsOneWidget);
    expect(find.text('همهٔ هزینه‌ها'), findsOneWidget);
  });

  testWidgets('materialize button records due recurring transactions once',
      (WidgetTester tester) async {
    final DateTime today = DateTime.now();
    final MemoryLedgerStore ledger = MemoryLedgerStore(
      FinancialLedger(accounts: <Account>[
        Account(
          id: 'acc-bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(10_000_000),
        ),
      ], recurrings: <RecurringTransaction>[
        RecurringTransaction(
          id: 'r1',
          name: 'قبض اینترنت',
          amount: const Money(50_000),
          kind: TransactionKind.expense,
          accountId: 'acc-bank',
          frequency: RecurringFrequency.daily,
          startDate: today.subtract(const Duration(days: 2)),
        ),
      ]),
    );
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('بودجه'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('materialize-button')));
    await tester.pumpAndSettle();
    expect(ledger.ledger!.transactions, hasLength(3));
    expect(find.textContaining('قبض اینترنت'), findsWidgets);

    await tester.tap(find.byKey(const Key('materialize-button')));
    await tester.pumpAndSettle();
    expect(ledger.ledger!.transactions, hasLength(3));
  });
}

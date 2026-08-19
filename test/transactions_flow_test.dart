import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/screens/home_screen.dart';
import 'package:maliiiii/maliiiii.dart';

import 'account_flow_test.dart' show pumpApp, seededProfile;
import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

FinancialLedger _seededLedger() => FinancialLedger(
      accounts: const <Account>[
        Account(
          id: 'acc-1',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: Money(10000000),
        ),
      ],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 't-e',
          accountId: 'acc-1',
          amount: const Money(200000),
          date: DateTime(2026, 8, 10),
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
        LedgerTransaction(
          id: 't-i',
          accountId: 'acc-1',
          amount: const Money(500000),
          date: DateTime(2026, 8, 12),
          kind: TransactionKind.income,
          category: 'حقوق',
        ),
      ],
    );

/// برنامه را با دفترکل نمونه باز کرده، ورودی «تاریخچه» را اسکرول و لمس
/// می‌کند و store را برمی‌گرداند تا تست‌ها روی منبع حقیقت assert کنند.
Future<MemoryLedgerStore> _openTransactionsList(WidgetTester tester) async {
  final MemoryLedgerStore store = MemoryLedgerStore(_seededLedger());
  await pumpApp(
    tester,
    MemoryProfileStore(seededProfile()),
    ledger: store,
  );
  await scrollToIn(
    tester,
    find.byKey(const Key('transactions-entry')),
    HomeScreen,
  );
  await tester.tap(find.byKey(const Key('transactions-entry')));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('transaction list shows entries and supports editing',
      (WidgetTester tester) async {
    await _openTransactionsList(tester);

    expect(find.text('خوراک'), findsOneWidget);
    expect(find.text('حقوق'), findsOneWidget);

    await tester.tap(find.text('خوراک'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tx-action-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('tx-amount')), '300000');
    await tester.tap(find.byKey(const Key('tx-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('۳۰۰'), findsWidgets);
    expect(find.text('خوراک'), findsOneWidget);
  });

  testWidgets('transaction can be deleted from the list',
      (WidgetTester tester) async {
    await _openTransactionsList(tester);

    await tester.tap(find.text('حقوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tx-action-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tx-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('حقوق'), findsNothing);
    expect(find.text('خوراک'), findsOneWidget);
  });

  testWidgets('account with transactions cannot be deleted',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: MemoryLedgerStore(_seededLedger()),
    );

    await tester.tap(find.text('حساب‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-edit-acc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-action-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account-card-acc-1')), findsOneWidget);
    expect(find.textContaining('تراکنش دارد'), findsOneWidget);
  });

  testWidgets('account can be renamed', (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore(_seededLedger());
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: store,
    );

    await tester.tap(find.text('حساب‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-edit-acc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-action-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('account-edit-name')), 'بانک ملی');
    await tester.tap(find.byKey(const Key('account-edit-save')));
    await tester.pumpAndSettle();

    // منبع حقیقت: دفترکل پایدارشده
    expect(store.ledger!.accounts.single.name, 'بانک ملی');
  });
}

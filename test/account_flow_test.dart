import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/add_account_screen.dart';
import 'package:maliiiii/app/screens/home_screen.dart';
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
  testWidgets('add account persists and appears in accounts tab',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore();
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('حساب‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز حسابی ثبت نکرده‌ای'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-account-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('account-name')), 'بانک ملی');
    await tester.enterText(
        find.byKey(const Key('account-opening')), '1000000');
    await tester.tap(find.byKey(const Key('account-type-bank')));
    await tester.pumpAndSettle();
    await scrollToIn(
      tester,
      find.byKey(const Key('account-save')),
      AddAccountScreen,
    );
    await tester.tap(find.byKey(const Key('account-save')));
    await tester.pumpAndSettle();

    expect(find.text('بانک ملی'), findsOneWidget);
    expect(ledger.ledger!.accounts, hasLength(1));
    expect(ledger.ledger!.accounts.single.type, AccountType.bank);
  });

  testWidgets('quick add buttons open income, expense and transfer screens',
      (WidgetTester tester) async {
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile);

    await scrollToIn(tester, find.text('ثبت هزینه'), HomeScreen);
    await tester.tap(find.text('ثبت هزینه'));
    await tester.pumpAndSettle();
    expect(find.text('هزینهٔ جدید'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await scrollToIn(tester, find.text('درآمد'), HomeScreen);
    await tester.tap(find.text('درآمد'));
    await tester.pumpAndSettle();
    expect(find.text('درآمد جدید'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await scrollToIn(tester, find.text('انتقال'), HomeScreen);
    await tester.tap(find.text('انتقال'));
    await tester.pumpAndSettle();
    expect(find.text('انتقال بین حساب‌ها'), findsOneWidget);
  });
}

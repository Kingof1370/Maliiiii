import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/screens/onboarding_screen.dart';
import 'package:maliiiii/maliiiii.dart';

import 'account_flow_test.dart' show pumpApp;
import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('onboarding creates the initial account with opening balance',
      (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    await pumpApp(tester, MemoryProfileStore(), ledger: store);

    // معرفی نمایش داده می‌شود
    expect(find.text('سلام 👋 به مالیار خوش آمدی'), findsOneWidget);

    // نام و نام خانوادگی
    await tester.enterText(find.byKey(const Key('field-first-name')), 'علی');
    await tester.enterText(find.byKey(const Key('field-last-name')), 'بهمنی');

    // حساب اول: نام پیش‌فرض «نقدی» + موجودی اولیه (ابتدا به پایین اسکرول)
    await scrollToIn(
      tester,
      find.byKey(const Key('initial-account-balance')),
      OnboardingScreen,
    );
    await tester.enterText(
        find.byKey(const Key('initial-account-balance')), '500000');

    // ثبت و ورود به خانه
    await scrollToIn(
      tester,
      find.byKey(const Key('profile-form-submit')),
      OnboardingScreen,
    );
    await tester.tap(find.byKey(const Key('profile-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('سلام علی 👋'), findsOneWidget);
    expect(store.ledger!.accounts.length, 1);
    expect(store.ledger!.accounts.single.name, 'نقدی');
    expect(store.ledger!.accounts.single.type, AccountType.cash);
    expect(store.ledger!.accounts.single.openingBalance.minorUnits, 500000);

    // در تب حساب‌ها هم دیده می‌شود (assert روی کارت حساب)
    await tester.tap(find.text('حساب‌ها'));
    await tester.pumpAndSettle();
    final String accountId = store.ledger!.accounts.single.id;
    expect(find.byKey(Key('account-card-$accountId')), findsOneWidget);
  });

  testWidgets('onboarding skips the account when the name is cleared',
      (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    await pumpApp(tester, MemoryProfileStore(), ledger: store);

    await tester.enterText(find.byKey(const Key('field-first-name')), 'علی');
    await tester.enterText(find.byKey(const Key('field-last-name')), 'بهمنی');
    await scrollToIn(
      tester,
      find.byKey(const Key('initial-account-name')),
      OnboardingScreen,
    );
    await tester.enterText(find.byKey(const Key('initial-account-name')), '');

    await scrollToIn(
      tester,
      find.byKey(const Key('profile-form-submit')),
      OnboardingScreen,
    );
    await tester.tap(find.byKey(const Key('profile-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('سلام علی 👋'), findsOneWidget);
    // بدون ایجاد حساب، هیچ commitای روی دفترکل انجام نمی‌شود
    expect(store.ledger?.accounts ?? const <Account>[], isEmpty);
  });
}

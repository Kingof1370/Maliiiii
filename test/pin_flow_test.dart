import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/settings_screen.dart';
import 'package:maliiiii/main.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

UserProfile seededProfile() =>
    UserProfile.create(firstName: 'علی', lastName: 'بهمنی');

Future<void> pumpApp(WidgetTester tester, ProfileStore store) async {
  await tester.pumpWidget(
    MaliiiiiApp(profileStore: store, ledgerStore: MemoryLedgerStore()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pin lock can be enabled, gates the app, and be removed',
      (WidgetTester tester) async {
    final MemoryProfileStore store = MemoryProfileStore(seededProfile());

    await pumpApp(tester, store);
    expect(find.text('سلام علی 👋'), findsOneWidget);

    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    await scrollToIn(
      tester,
      find.byKey(const Key('settings-set-pin')),
      SettingsScreen,
    );
    await tester.tap(find.byKey(const Key('settings-set-pin')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pin-set-input1')), '1234');
    await tester.enterText(find.byKey(const Key('pin-set-input2')), '5678');
    await tester.tap(find.byKey(const Key('pin-set-save')));
    await tester.pumpAndSettle();
    expect(find.text('رمزها یکسان نیستند.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin-set-input2')), '1234');
    await tester.tap(find.byKey(const Key('pin-set-save')));
    await tester.pumpAndSettle();
    expect(find.text('رمزها یکسان نیستند.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, store);
    expect(find.text('قفل برنامه'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin-unlock-input')), '0000');
    await tester.tap(find.byKey(const Key('pin-unlock-submit')));
    await tester.pumpAndSettle();
    expect(find.text('رمز اشتباه است'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin-unlock-input')), '1234');
    await tester.tap(find.byKey(const Key('pin-unlock-submit')));
    await tester.pumpAndSettle();
    expect(find.text('سلام علی 👋'), findsOneWidget);

    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    await scrollToIn(
      tester,
      find.byKey(const Key('settings-remove-pin')),
      SettingsScreen,
    );
    await tester.tap(find.byKey(const Key('settings-remove-pin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pin-remove-confirm')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, store);
    expect(find.text('سلام علی 👋'), findsOneWidget);
  });
}

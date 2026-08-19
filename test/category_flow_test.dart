import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/screens/home_screen.dart';
import 'package:maliiiii/maliiiii.dart';

import 'account_flow_test.dart' show pumpApp, seededProfile;
import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('expense form offers a seeded custom category',
      (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore(FinancialLedger(
      customCategories: const <UserCategory>[
        UserCategory(id: 'c1', name: 'حیات‌وحوش', kind: CategoryKind.expense),
      ],
    ));
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: store,
    );
    await tester.pumpAndSettle();

    // tab پیش‌فرض خانه است؛ ابتدا به دکمهٔ افزودن سریع اسکرول می‌کنیم.
    await scrollToIn(
      tester,
      find.byKey(const Key('quick-add-expense')),
      HomeScreen,
    );
    await tester.tap(find.byKey(const Key('quick-add-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tx-category')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('حیات‌وحوش'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('حیات‌وحوش'), findsOneWidget);
  });

  testWidgets('add from settings and delete from manage screen',
      (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: store,
    );
    await tester.pumpAndSettle();

    // افزودن دسته از تنظیمات
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دسته‌های سفارشی'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-cat-expense')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('manage-category-name')), 'حیات‌وحوش');
    await tester.tap(find.byKey(const Key('manage-category-save')));
    await tester.pumpAndSettle();

    expect(find.text('حیات‌وحوش'), findsOneWidget);
    final String id = store.ledger!.customCategories.single.id;
    expect(id, isNotEmpty);

    // حذف همان دسته
    await tester.tap(find.byKey(Key('cat-delete-$id')));
    await tester.pumpAndSettle();
    expect(find.text('حیات‌وحوش'), findsNothing);
    expect(store.ledger!.customCategories, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/screens/calendar_screen.dart';
import 'package:maliiiii/maliiiii.dart';

import 'account_flow_test.dart' show pumpApp, seededProfile;
import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

String _todayKey() {
  final JalaliDate today = JalaliDate.fromDateTime(DateTime.now());
  return '${today.year}-${today.month}-${today.day}';
}

void main() {
  testWidgets('calendar shows a seeded daily note', (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore(FinancialLedger(
      dailyNotes: <DailyNote>[
        DailyNote(
          id: 'n1',
          dateKey: _todayKey(),
          text: 'قرار ملاقات با بانک',
          createdAt: DateTime.now(),
        ),
      ],
    ));
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: store,
    );
    await tester.tap(find.text('تقویم'));
    await tester.pumpAndSettle();

    await scrollToIn(
      tester,
      find.text('قرار ملاقات با بانک'),
      CalendarScreen,
    );
    expect(find.text('قرار ملاقات با بانک'), findsOneWidget);
    expect(find.byKey(const Key('cal-note-delete')), findsOneWidget);
  });

  testWidgets('add a daily note from the calendar', (WidgetTester tester) async {
    final MemoryLedgerStore store = MemoryLedgerStore();
    await pumpApp(
      tester,
      MemoryProfileStore(seededProfile()),
      ledger: store,
    );
    await tester.tap(find.text('تقویم'));
    await tester.pumpAndSettle();

    await scrollToIn(
      tester,
      find.byKey(const Key('cal-note-button')),
      CalendarScreen,
    );
    await tester.tap(find.byKey(const Key('cal-note-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('note-text')), 'برنامهٔ فردا: پرداخت قبض');
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle();

    expect(find.text('برنامهٔ فردا: پرداخت قبض'), findsOneWidget);
    final String key = _todayKey();
    expect(store.ledger!.dailyNotes.length, 1);
    expect(store.ledger!.dailyNotes.single.dateKey, key);
  });
}

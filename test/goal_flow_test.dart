import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/add_goal_screen.dart';
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
  testWidgets('add goal via UI persists and shows progress',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore();
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('اهداف'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز هدفی ثبت نشده است'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-goal-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('goal-name')), 'خرید خانه');
    await tester.enterText(find.byKey(const Key('goal-target')), '1000000');
    await tester.tap(find.byKey(const Key('goal-type-purchase')));
    await tester.pumpAndSettle();

    await scrollToIn(
      tester,
      find.byKey(const Key('goal-save')),
      AddGoalScreen,
    );
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(ledger.ledger!.goals, hasLength(1));
    expect(ledger.ledger!.goals.single.type, GoalType.purchase);
    expect(find.text('خرید خانه'), findsOneWidget);
    expect(find.text('۰٪'), findsNWidgets(2));
  });

  testWidgets('contribute via UI updates progress to 40 percent',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore(
      FinancialLedger(goals: <Goal>[
        Goal(
          id: 'goal-1',
          name: 'سفر',
          type: GoalType.savings,
          target: const Money(1_000_000),
          current: const Money(0),
          deadline: DateTime(2027, 3, 20),
          priority: 3,
        ),
      ]),
    );
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('اهداف'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('goal-contribute-goal-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('goal-contribute-amount')),
      '400000',
    );
    await tester.tap(find.byKey(const Key('goal-contribute-submit')));
    await tester.pumpAndSettle();

    expect(ledger.ledger!.goals.single.current.minorUnits, 400_000);
    expect(find.text('۴۰٪'), findsNWidgets(2));
  });
}

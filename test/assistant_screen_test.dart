import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/data/profile_repository.dart';
import 'package:maliiiii/app/screens/assistant_screen.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/app/state/ledger_scope.dart';
import 'package:maliiiii/app/state/profile_controller.dart';
import 'package:maliiiii/app/state/profile_scope.dart';
import 'package:maliiiii/app/theme/app_theme.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';

void main() {
  FinancialLedger seededLedger() => FinancialLedger(
        accounts: <Account>[
          Account(
            id: 'cash',
            name: 'نقدی',
            type: AccountType.cash,
            openingBalance: const Money(1_000_000),
          ),
        ],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'i1',
            accountId: 'cash',
            amount: const Money(2_000_000),
            date: DateTime(2026, 8, 5),
            kind: TransactionKind.income,
            category: 'حقوق',
          ),
          LedgerTransaction(
            id: 'e1',
            accountId: 'cash',
            amount: const Money(500_000),
            date: DateTime(2026, 8, 10),
            kind: TransactionKind.expense,
            category: 'خوراک',
          ),
        ],
      );

  Future<void> pumpAssistant(
    WidgetTester tester, {
    required FinancialLedger ledger,
    bool aiEnabled = true,
  }) async {
    final LedgerController ledgerController =
        LedgerController(LedgerRepository(MemoryLedgerStore(ledger)));
    await ledgerController.init();
    final UserProfile profile =
        UserProfile.create(firstName: 'علی', lastName: 'بهمنی')
            .copyWith(aiEnabled: aiEnabled);
    final ProfileController profileController =
        ProfileController(ProfileRepository(MemoryProfileStore(profile)));
    await profileController.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: ProfileScope(
          controller: profileController,
          child: LedgerScope(
            controller: ledgerController,
            child: const AssistantScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('assistant renders insight cards from the ledger',
      (tester) async {
    await pumpAssistant(tester, ledger: seededLedger());
    expect(find.text('دستیار هوشمند'), findsOneWidget);
    expect(find.text('نمای کلی'), findsOneWidget);
  });

  testWidgets('assistant shows empty state without data', (tester) async {
    await pumpAssistant(tester, ledger: const FinancialLedger());
    expect(find.text('هنوز داده‌ای برای تحلیل نیست'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/add_loan_screen.dart';
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
  testWidgets('add loan with auto schedule persists and shows in list',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore();
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('وام‌ها و بدهی‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز وامی ثبت نشده است'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-loan-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('loan-title')), 'وام خودرو');
    await tester.enterText(
        find.byKey(const Key('loan-principal')), '1200000');
    await tester.enterText(find.byKey(const Key('loan-interest')), '120000');

    await scrollToIn(
      tester,
      find.byKey(const Key('loan-auto-schedule')),
      AddLoanScreen,
    );
    await tester.tap(find.byKey(const Key('loan-auto-schedule')));
    await tester.pumpAndSettle();
    // فعال‌شدن سوییچ باید فیلد تعداد اقساط را نمایان کند.
    expect(find.byKey(const Key('loan-installments-count')), findsOneWidget);

    await scrollToIn(
      tester,
      find.byKey(const Key('loan-save')),
      AddLoanScreen,
    );
    expect(find.byKey(const Key('loan-save')), findsOneWidget);
    await tester.tap(find.byKey(const Key('loan-save')));
    await tester.pumpAndSettle();

    expect(ledger.ledger, isNotNull);
    expect(ledger.ledger!.loans, hasLength(1));
    expect(ledger.ledger!.loans.single.title, 'وام خودرو');
    expect(ledger.ledger!.loans.single.installments, hasLength(12));

    expect(find.text('وام خودرو'), findsOneWidget);
    expect(find.textContaining('قسط بعدی'), findsOneWidget);
    expect(find.textContaining('۱,۳۲۰,۰۰۰ تومان'), findsWidgets);
  });

  testWidgets('loan detail shows installments with Persian status',
      (WidgetTester tester) async {
    final MemoryLedgerStore ledger = MemoryLedgerStore(
      FinancialLedger(accounts: <Account>[
        Account(
          id: 'acc-bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(10_000_000),
        ),
      ], loans: <Loan>[
        Loan(
          id: 'loan-1',
          title: 'وام خودرو',
          lender: 'بانک ملی',
          principal: const Money(1_200_000),
          receivedAmount: const Money(1_200_000),
          interest: const Money(0),
          fees: const Money(0),
          totalPayable: const Money(1_200_000),
          startDate: DateTime(2026, 8, 1),
          installments: <Installment>[
            Installment(
              id: 'inst-1',
              loanId: 'loan-1',
              number: 1,
              dueDate: DateTime(2026, 9, 1),
              totalAmount: const Money(600_000),
            ),
            Installment(
              id: 'inst-2',
              loanId: 'loan-1',
              number: 2,
              dueDate: DateTime(2026, 10, 1),
              totalAmount: const Money(600_000),
            ),
          ],
        ),
      ]),
    );
    final MemoryProfileStore profile = MemoryProfileStore(seededProfile());
    await pumpApp(tester, profile, ledger: ledger);

    await tester.tap(find.text('وام‌ها و بدهی‌ها'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('وام خودرو'));
    await tester.pumpAndSettle();

    expect(find.text('قسط ۱'), findsOneWidget);
    expect(find.text('قسط ۲'), findsOneWidget);
    expect(find.text('آینده'), findsNWidgets(2));
    expect(find.textContaining('پرداخت'), findsWidgets);
  });
}

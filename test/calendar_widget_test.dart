import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/screens/calendar_screen.dart';
import 'package:maliiiii/main.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';
import 'memory_profile_store.dart';
import 'test_helpers.dart';

UserProfile seededProfile() =>
    UserProfile.create(firstName: 'علی', lastName: 'بهمنی');

void main() {
  testWidgets('calendar tab shows current jalali month and day events',
      (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final JalaliDate today = JalaliDate.fromDateTime(now);

    final FinancialLedger seededLedger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(1000000),
        ),
        Account(
          id: 'cash',
          name: 'نقدی',
          type: AccountType.cash,
          openingBalance: const Money(0),
        ),
      ],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'inc1',
          accountId: 'bank',
          amount: const Money(500000),
          date: now,
          kind: TransactionKind.income,
          category: 'حقوق',
        ),
        LedgerTransaction(
          id: 'exp1',
          accountId: 'bank',
          amount: const Money(200000),
          date: now,
          kind: TransactionKind.expense,
          category: 'خوراک',
        ),
      ],
      loans: <Loan>[
        Loan(
          id: 'loan1',
          title: 'وام خودرو',
          lender: 'بانک',
          principal: const Money(10000000),
          receivedAmount: const Money(10000000),
          interest: const Money(0),
          fees: const Money(0),
          totalPayable: const Money(10000000),
          startDate: now,
          installments: <Installment>[
            Installment(
              id: 'i1',
              loanId: 'loan1',
              number: 1,
              dueDate: now,
              totalAmount: const Money(300000),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaliiiiiApp(
        profileStore: MemoryProfileStore(seededProfile()),
        ledgerStore: MemoryLedgerStore(seededLedger),
      ),
    );
    await tester.pumpAndSettle();

    // رفتن به تب تقویم (با آیکون تا با عنوان صفحه تداخل نکند)
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    // عنوان ماه شمسی جاری
    expect(find.textContaining(toPersianDigits(today.year)), findsWidgets);
    expect(find.textContaining(today.monthName), findsWidgets);

    // جزئیات روز انتخاب‌شده (= امروز) با رویدادهای دفترکل
    await scrollToIn(
      tester,
      find.textContaining('حقوق'),
      CalendarScreen,
    );
    expect(find.textContaining('حقوق'), findsOneWidget);
    expect(find.textContaining('خوراک'), findsOneWidget);
    expect(find.textContaining('قسط: وام خودرو'), findsOneWidget);
  });
}

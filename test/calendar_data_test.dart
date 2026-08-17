import 'package:maliiiii/app/state/calendar_data.dart';
import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  final DateTime day = DateTime(2026, 8, 17);
  final JalaliDate jalaliDay = JalaliDate.fromGregorian(day);

  FinancialLedger seededLedger() => FinancialLedger(
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
            date: day,
            kind: TransactionKind.income,
            category: 'حقوق',
          ),
          LedgerTransaction(
            id: 'exp1',
            accountId: 'bank',
            amount: const Money(200000),
            date: day,
            kind: TransactionKind.expense,
            category: 'خوراک',
          ),
          LedgerTransaction(
            id: 'tr:out',
            accountId: 'bank',
            amount: const Money(100000),
            date: day,
            kind: TransactionKind.transferOut,
            transferId: 'tr1',
          ),
          LedgerTransaction(
            id: 'tr:in',
            accountId: 'cash',
            amount: const Money(100000),
            date: day,
            kind: TransactionKind.transferIn,
            transferId: 'tr1',
          ),
          // رویداد روز دیگر — نباید در این روز ظاهر شود
          LedgerTransaction(
            id: 'inc-other',
            accountId: 'bank',
            amount: const Money(999999),
            date: DateTime(2026, 8, 10),
            kind: TransactionKind.income,
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
            startDate: DateTime(2026, 7, 1),
            installments: <Installment>[
              Installment(
                id: 'i1',
                loanId: 'loan1',
                number: 1,
                dueDate: day,
                totalAmount: const Money(300000),
              ),
            ],
          ),
        ],
      );

  test('eventsForDay groups income, expense, one transfer and installment',
      () {
    final List<DayEvent> events = eventsForDay(jalaliDay, seededLedger());

    expect(events, hasLength(4));
    expect(
      events.where((e) => e.kind == CalendarEventKind.income),
      hasLength(1),
    );
    expect(
      events.where((e) => e.kind == CalendarEventKind.expense),
      hasLength(1),
    );
    // انتقال فقط یک‌بار شمرده می‌شود (سمت خروج)
    expect(
      events.where((e) => e.kind == CalendarEventKind.transfer),
      hasLength(1),
    );
    expect(
      events.where((e) => e.kind == CalendarEventKind.installmentDue),
      hasLength(1),
    );

    final DayEvent income =
        events.firstWhere((e) => e.kind == CalendarEventKind.income);
    expect(income.title, 'حقوق');
    expect(income.amount, const Money(500000));
  });

  test('events of another day do not leak into this day', () {
    final List<DayEvent> events = eventsForDay(jalaliDay, seededLedger());
    expect(
      events.any((e) => e.amount == const Money(999999)),
      isFalse,
    );
  });

  test('dayStatus counts income vs expense only (transfers neutral)', () {
    final List<DayEvent> events = eventsForDay(jalaliDay, seededLedger());
    // درآمد ۵۰۰٬۰۰۰ − هزینه ۲۰۰٬۰۰۰ = مثبت
    expect(dayStatus(events), 1);
  });

  test('dayStatus negative when expense exceeds income', () {
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(1000000),
        ),
      ],
      transactions: <LedgerTransaction>[
        LedgerTransaction(
          id: 'exp1',
          accountId: 'bank',
          amount: const Money(400000),
          date: day,
          kind: TransactionKind.expense,
        ),
        LedgerTransaction(
          id: 'inc1',
          accountId: 'bank',
          amount: const Money(100000),
          date: day,
          kind: TransactionKind.income,
        ),
      ],
    );
    expect(dayStatus(eventsForDay(jalaliDay, ledger)), -1);
  });

  test('empty day has no events and neutral status', () {
    final FinancialLedger ledger = FinancialLedger(
      accounts: <Account>[
        Account(
          id: 'bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(1),
        ),
      ],
    );
    expect(eventsForDay(jalaliDay, ledger), isEmpty);
    expect(dayStatus(const <DayEvent>[]), 0);
  });
}

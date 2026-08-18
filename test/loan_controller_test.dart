import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/ledger_repository.dart';
import 'package:maliiiii/app/state/ledger_controller.dart';
import 'package:maliiiii/app/state/loan_controller.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_ledger_store.dart';

void main() {
  late MemoryLedgerStore store;
  late LedgerController ledger;
  late LoanController loans;

  DateTime date(int year, [int month = 1, int day = 1]) =>
      DateTime(year, month, day);

  setUp(() async {
    store = MemoryLedgerStore(
      FinancialLedger(accounts: <Account>[
        Account(
          id: 'acc-bank',
          name: 'بانک',
          type: AccountType.bank,
          openingBalance: const Money(10_000_000),
        ),
      ]),
    );
    ledger = LedgerController(LedgerRepository(store));
    loans = LoanController(ledger);
    await ledger.init(); // دفترکل از فروشگاه بارگذاری شود
  });

  Loan sampleLoan(String id, {int totalPayable = 1_200_000, int count = 3}) =>
      Loan(
        id: id,
        title: 'وام خودرو',
        lender: 'بانک ملی',
        principal: Money(totalPayable),
        receivedAmount: Money(totalPayable),
        interest: const Money(0),
        fees: const Money(0),
        totalPayable: Money(totalPayable),
        startDate: date(2026, 8, 1),
        installments: LoanSchedule.equalMonthly(
          loanId: id,
          count: count,
          totalPayable: Money(totalPayable),
          firstDue: const JalaliDate(1405, 7, 1),
        ),
      );

  test('create loan persists to the store', () async {
    await loans.createLoan(loan: sampleLoan('loan-1'));
    expect(store.ledger!.loans, hasLength(1));
    expect(store.ledger!.loans.single.title, 'وام خودرو');
    expect(loans.loans.single.installments, hasLength(3));
    expect(loans.outstandingDebt.minorUnits, 1_200_000);
  });

  test('irregular installments and two installments on the same day are allowed',
      () async {
    await loans.createLoan(loan: sampleLoan('loan-2', count: 1));
    await loans.addInstallment(
      loanId: 'loan-2',
      installment: Installment(
        id: 'inst-x',
        loanId: 'loan-2',
        number: 2,
        dueDate: date(2026, 10, 10),
        totalAmount: const Money(300_000),
      ),
    );
    await loans.addInstallment(
      loanId: 'loan-2',
      installment: Installment(
        id: 'inst-y',
        loanId: 'loan-2',
        number: 3,
        dueDate: date(2026, 10, 10), // همان روز
        totalAmount: const Money(700_000),
      ),
    );
    final Loan loan = loans.loanById('loan-2')!;
    expect(loan.installments, hasLength(3));
    final int sameDayCount = loan.installments
        .where((item) => item.dueDate == date(2026, 10, 10))
        .length;
    expect(sameDayCount, 2);
  });

  test('partial then full payment updates balances and persists', () async {
    await loans.createLoan(loan: sampleLoan('loan-3', totalPayable: 1_000_000, count: 1));
    final Installment installment = loans.loanById('loan-3')!.installments.single;
    final PaymentReceipt first = await loans.recordPayment(
      paymentId: 'pay-1',
      ledgerEntryId: 'ledger-1',
      loanId: 'loan-3',
      installmentId: installment.id,
      accountId: 'acc-bank',
      amount: const Money(400_000),
      paidDate: date(2026, 8, 10),
    );
    expect(first.installment.paidAmount.minorUnits, 400_000);
    expect(first.installment.remainingAmount.minorUnits, 600_000);
    expect(store.ledger!.accountBalance('acc-bank').minorUnits, 9_600_000);

    final PaymentReceipt second = await loans.recordPayment(
      paymentId: 'pay-2',
      ledgerEntryId: 'ledger-2',
      loanId: 'loan-3',
      installmentId: installment.id,
      accountId: 'acc-bank',
      amount: const Money(600_000),
      paidDate: date(2026, 8, 20),
    );
    expect(second.installment.remainingAmount.isZero, isTrue);
    expect(second.installment.statusAt(date(2026, 8, 21)), InstallmentStatus.paid);
    expect(store.ledger!.accountBalance('acc-bank').minorUnits, 9_000_000);
    expect(loans.outstandingDebt.isZero, isTrue);
  });

  test('reschedule changes due date and marks the installment', () async {
    await loans.createLoan(loan: sampleLoan('loan-4', count: 1));
    final String installmentId =
        loans.loanById('loan-4')!.installments.single.id;
    await loans.rescheduleInstallment(
      loanId: 'loan-4',
      installmentId: installmentId,
      newDueDate: date(2026, 12, 1),
    );
    final Installment updated = loans
        .loanById('loan-4')!
        .installments
        .single;
    expect(updated.dueDate, date(2026, 12, 1));
    expect(updated.rescheduled, isTrue);
    expect(
      updated.statusAt(date(2026, 8, 18)),
      isNot(InstallmentStatus.overdue),
    );
  });

  test('cancel works for unpaid installment and is rejected for paid one',
      () async {
    await loans.createLoan(loan: sampleLoan('loan-5', count: 1));
    final String installmentId =
        loans.loanById('loan-5')!.installments.single.id;
    await loans.cancelInstallment(
      loanId: 'loan-5',
      installmentId: installmentId,
    );
    expect(
      loans.loanById('loan-5')!.installments.single.statusAt(date(2026, 8, 18)),
      InstallmentStatus.cancelled,
    );

    // وام دوم با قسط پرداخت‌شده؛ لغو باید رد شود.
    await loans.createLoan(loan: sampleLoan('loan-6', totalPayable: 100, count: 1));
    final Installment paidInstallment =
        loans.loanById('loan-6')!.installments.single;
    await loans.recordPayment(
      paymentId: 'pay-3',
      ledgerEntryId: 'ledger-3',
      loanId: 'loan-6',
      installmentId: paidInstallment.id,
      accountId: 'acc-bank',
      amount: const Money(100),
      paidDate: date(2026, 8, 10),
    );
    await expectLater(
      loans.cancelInstallment(
        loanId: 'loan-6',
        installmentId: paidInstallment.id,
      ),
      throwsA(isA<FinancialValidationException>()),
    );
  });

  test('complete only when zero remaining; archive always allowed', () async {
    await loans.createLoan(loan: sampleLoan('loan-7', totalPayable: 100, count: 1));
    final String installmentId =
        loans.loanById('loan-7')!.installments.single.id;

    // تسویه با باقی‌مانده رد می‌شود.
    await expectLater(
      loans.completeLoan(loanId: 'loan-7'),
      throwsA(isA<FinancialValidationException>()),
    );

    await loans.recordPayment(
      paymentId: 'pay-4',
      ledgerEntryId: 'ledger-4',
      loanId: 'loan-7',
      installmentId: installmentId,
      accountId: 'acc-bank',
      amount: const Money(100),
      paidDate: date(2026, 8, 10),
    );
    await loans.completeLoan(loanId: 'loan-7');
    expect(loans.loanById('loan-7')!.status, LoanStatus.paidOff);

    await loans.archiveLoan(loanId: 'loan-7');
    expect(loans.loanById('loan-7')!.status, LoanStatus.archived);
  });

  test('invalid payments are rejected and nothing persists', () async {
    await loans.createLoan(loan: sampleLoan('loan-8', totalPayable: 500, count: 1));
    final String installmentId =
        loans.loanById('loan-8')!.installments.single.id;
    final int balanceBefore = store.ledger!.accountBalance('acc-bank').minorUnits;

    // مبلغ بیش از باقی‌مانده.
    await expectLater(
      loans.recordPayment(
        paymentId: 'pay-bad-1',
        ledgerEntryId: 'ledger-bad-1',
        loanId: 'loan-8',
        installmentId: installmentId,
        accountId: 'acc-bank',
        amount: const Money(999_999),
        paidDate: date(2026, 8, 10),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    // حساب ناشناخته.
    await expectLater(
      loans.recordPayment(
        paymentId: 'pay-bad-2',
        ledgerEntryId: 'ledger-bad-2',
        loanId: 'loan-8',
        installmentId: installmentId,
        accountId: 'acc-missing',
        amount: const Money(100),
        paidDate: date(2026, 8, 10),
      ),
      throwsA(isA<FinancialValidationException>()),
    );
    // وام ناشناخته.
    await expectLater(
      loans.completeLoan(loanId: 'loan-missing'),
      throwsA(isA<FinancialValidationException>()),
    );
    // هیچ تغییری روی دیسک ننشسته است.
    expect(store.ledger!.loans.single.installments.single.payments, isEmpty);
    expect(
      store.ledger!.accountBalance('acc-bank').minorUnits,
      balanceBefore,
    );
  });
}

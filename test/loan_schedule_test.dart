import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

// JalaliDate معادل ساز (==) ندارد؛ مقایسه با isSameDay انجام می‌شود.
bool sameDay(JalaliDate a, JalaliDate b) => a.isSameDay(b);

void main() {
  test('equalMonthly sums exactly to total payable', () {
    final List<Installment> installments = LoanSchedule.equalMonthly(
      loanId: 'loan-1',
      count: 12,
      totalPayable: const Money(1_320_000),
      firstDue: const JalaliDate(1405, 1, 1),
    );
    expect(installments, hasLength(12));
    final int total = installments.fold<int>(
      0,
      (sum, item) => sum + item.totalAmount.minorUnits,
    );
    expect(total, 1_320_000);
    // توزیع باقی‌مانده: ۱٬۳۲۰٬۰۰۰ / ۱۲ = ۱۱۰٬۰۰۰
    expect(installments.first.totalAmount.minorUnits, 110_000);
    expect(installments.last.totalAmount.minorUnits, 110_000);
  });

  test('remainder is distributed to the first installments', () {
    final List<Installment> installments = LoanSchedule.equalMonthly(
      loanId: 'loan-2',
      count: 3,
      totalPayable: const Money(100),
      firstDue: const JalaliDate(1405, 2, 1),
    );
    expect(installments[0].totalAmount.minorUnits, 34); // 100 ~/ 3 + 1
    expect(installments[1].totalAmount.minorUnits, 33);
    expect(installments[2].totalAmount.minorUnits, 33);
    final int total = installments.fold<int>(
      0,
      (sum, item) => sum + item.totalAmount.minorUnits,
    );
    expect(total, 100);
  });

  test('due dates advance by Persian months crossing the leap Esfand', () {
    // اسفند ۱۴۰۳ کبیسه است (۳۰ روز): قسط بعدی باید اول فروردین ۱۴۰۴ باشد.
    final List<Installment> installments = LoanSchedule.equalMonthly(
      loanId: 'loan-3',
      count: 3,
      totalPayable: const Money(300),
      firstDue: const JalaliDate(1403, 12, 15),
    );
    expect(
      sameDay(JalaliDate.fromDateTime(installments[0].dueDate), const JalaliDate(1403, 12, 15)),
      isTrue,
    );
    expect(
      sameDay(JalaliDate.fromDateTime(installments[1].dueDate), const JalaliDate(1404, 1, 15)),
      isTrue,
    );
    expect(
      sameDay(JalaliDate.fromDateTime(installments[2].dueDate), const JalaliDate(1404, 2, 15)),
      isTrue,
    );
  });

  test('ids are unique and carry the loan prefix', () {
    final List<Installment> installments = LoanSchedule.equalMonthly(
      loanId: 'loan-4',
      count: 5,
      totalPayable: const Money(500),
      firstDue: const JalaliDate(1405, 3, 1),
      idPrefix: 'inst',
    );
    expect(installments.map((item) => item.id).toSet(), hasLength(5));
    expect(installments.first.id, 'inst-1');
    expect(installments.last.id, 'inst-5');
    expect(installments.every((item) => item.loanId == 'loan-4'), isTrue);
  });

  test('invalid input is rejected', () {
    expect(
      () => LoanSchedule.equalMonthly(
        loanId: 'l',
        count: 0,
        totalPayable: const Money(100),
        firstDue: const JalaliDate(1405, 1, 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => LoanSchedule.equalMonthly(
        loanId: 'l',
        count: 3,
        totalPayable: const Money(-1),
        firstDue: const JalaliDate(1405, 1, 1),
      ),
      throwsArgumentError,
    );
  });
}

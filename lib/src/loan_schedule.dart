import 'calendar.dart';
import 'models.dart';
import 'money.dart';

/// برنامه‌ریز خودکار اقساط با مبنای شمسی.
///
/// قسط‌ها روی ماه‌های شمسی با [JalaliDate.addMonths] جلو می‌روند که نسبت به
/// کبیسه خنثی است (اسفند ۲۹ یا ۳۰ روزه درست مدیریت می‌شود). مجموع قسط‌ها
/// دقیقاً برابر کل بدهی است؛ باقی‌ماندهٔ تقسیم (واحدهای کوچک) به قسط‌های
/// اول توزیع می‌شود تا جمع ریالی دقیق بماند و هیچ عددی گم نشود.
final class LoanSchedule {
  const LoanSchedule._();

  /// تولید [count] قسط مساوی با سررسید اول [firstDue] و فاصلهٔ
  /// [intervalMonths] ماه شمسی. شناسهٔ قسط‌ها «<idPrefix>-<شماره>» است.
  static List<Installment> equalMonthly({
    required String loanId,
    required int count,
    required Money totalPayable,
    required JalaliDate firstDue,
    int intervalMonths = 1,
    String idPrefix = 'inst',
  }) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be at least 1');
    }
    if (intervalMonths < 1) {
      throw ArgumentError.value(
        intervalMonths,
        'intervalMonths',
        'must be at least 1',
      );
    }
    if (!totalPayable.isPositive) {
      throw ArgumentError.value(totalPayable, 'totalPayable', 'must be positive');
    }
    final int base = totalPayable.minorUnits ~/ count;
    final int remainder = totalPayable.minorUnits % count;
    return List<Installment>.generate(count, (int index) {
      final int extra = index < remainder ? 1 : 0;
      final JalaliDate due = firstDue.addMonths(index * intervalMonths);
      return Installment(
        id: '$idPrefix-${index + 1}',
        loanId: loanId,
        number: index + 1,
        dueDate: due.toGregorian(),
        totalAmount: Money(base + extra, currency: totalPayable.currency),
      );
    });
  }
}

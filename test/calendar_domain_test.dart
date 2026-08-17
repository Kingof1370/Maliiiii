import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  test('month lengths are 31/30/29 with correct leap detection', () {
    expect(JalaliDate.daysInMonth(1404, 1), 31);
    expect(JalaliDate.daysInMonth(1404, 6), 31);
    expect(JalaliDate.daysInMonth(1404, 7), 30);
    expect(JalaliDate.daysInMonth(1404, 11), 30);
    expect(JalaliDate.daysInMonth(1404, 12), 29); // ۱۴۰۴ کبیسه نیست
    expect(JalaliDate.isLeapYear(1404), isFalse);

    // سال ۱۴۰۳ کبیسه بود (اسفند ۳۰ روز).
    expect(JalaliDate.isLeapYear(1403), isTrue);
    expect(JalaliDate.daysInMonth(1403, 12), 30);
  });

  test('sum of month lengths matches year length', () {
    int yearLength(int year) => List<int>.generate(
          12,
          (index) => JalaliDate.daysInMonth(year, index + 1),
        ).reduce((a, b) => a + b);

    expect(yearLength(1403), 366);
    expect(yearLength(1404), 365);
  });

  test('addMonths crosses year boundaries', () {
    final JalaliDate first = JalaliDate(1405, 1, 1).addMonths(1);
    expect(first.year, 1405);
    expect(first.month, 2);
    expect(first.day, 1);

    final JalaliDate esfand = JalaliDate(1404, 12, 15).addMonths(1);
    expect(esfand.year, 1405);
    expect(esfand.month, 1);
    expect(esfand.day, 15);

    final JalaliDate autumn = JalaliDate(1405, 7, 1).addMonths(6);
    expect(autumn.year, 1406);
    expect(autumn.month, 1);

    final JalaliDate back = JalaliDate(1405, 1, 1).addMonths(-1);
    expect(back.year, 1404);
    expect(back.month, 12);
    expect(back.day, 1);
  });

  test('weekday index is Saturday-based and names are persian', () {
    // نوروز ۱۴۰۵ = ۱ فروردین = شنبهٔ ۲۱ مارس ۲۰۲۶
    final JalaliDate norouz = JalaliDate.fromGregorian(DateTime(2026, 3, 21));
    expect(norouz.year, 1405);
    expect(norouz.month, 1);
    expect(norouz.day, 1);
    expect(norouz.weekdayIndex, 0);
    expect(norouz.weekdayName, 'شنبه');
    expect(norouz.monthName, 'فروردین');

    // ۲۹ بهمن ۱۴۰۴ = جمعهٔ ۱۸ فوریهٔ ۲۰۲۶؟ (بررسی سازگاری با weekday)
    // به‌جای حدس، سازگاری هفته را با round-trip بررسی می‌کنیم:
    final DateTime gregorian = DateTime(2026, 8, 17);
    final JalaliDate converted = JalaliDate.fromGregorian(gregorian);
    expect(converted.toGregorian(), gregorian);
    expect(converted.weekdayIndex, (gregorian.weekday + 1) % 7);
  });

  test('isSameDay compares calendar days only', () {
    expect(
      JalaliDate(1405, 5, 26).isSameDay(JalaliDate(1405, 5, 26)),
      isTrue,
    );
    expect(
      JalaliDate(1405, 5, 26).isSameDay(JalaliDate(1405, 5, 27)),
      isFalse,
    );
  });
}

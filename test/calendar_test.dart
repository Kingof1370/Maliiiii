import 'package:maliiiii/maliiiii.dart';
import 'package:test/test.dart';

void main() {
  test('Jalali conversion preserves a known date', () {
    final jalali = JalaliDate.fromGregorian(DateTime(2026, 3, 21));
    expect(jalali.year, 1405);
    expect(jalali.month, 1);
    expect(jalali.day, 1);
    expect(jalali.toGregorian(), DateTime(2026, 3, 21));
  });

  test('Persian digit and money formatting are deterministic', () {
    expect(toPersianDigits(1405), '۱۴۰۵');
    expect(formatMinorUnits(1250000), '۱,۲۵۰,۰۰۰ تومان');
    expect(formatMinorUnits(-500), '-۵۰۰ تومان');
  });
}
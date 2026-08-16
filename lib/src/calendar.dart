final class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  DateTime toGregorian() {
    final jy = year + 1595;
    var days = -355668 +
        (365 * jy) +
        (jy ~/ 33) * 8 +
        (((jy % 33) + 3) ~/ 4) +
        day +
        (month < 7 ? (month - 1) * 31 : (month - 7) * 30 + 186);
    var gy = 400 * (days ~/ 146097);
    days %= 146097;
    if (days > 36524) {
      gy += 100 * (--days ~/ 36524);
      days %= 36524;
      if (days >= 365) days++;
    }
    gy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      gy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    var gd = days + 1;
    final monthLengths = <int>[31, _isGregorianLeap(gy) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    var gm = 0;
    while (gm < monthLengths.length && gd > monthLengths[gm]) {
      gd -= monthLengths[gm];
      gm++;
    }
    return DateTime(gy, gm + 1, gd);
  }

  static JalaliDate fromGregorian(DateTime date) {
    final gy = date.year - 1600;
    final gm = date.month - 1;
    final gd = date.day - 1;
    var days = 365 * gy +
        ((gy + 3) ~/ 4) -
        ((gy + 99) ~/ 100) +
        ((gy + 399) ~/ 400);
    const monthLengths = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    for (var index = 0; index < gm; index++) {
      days += monthLengths[index];
    }
    if (gm > 1 && _isGregorianLeap(date.year)) days++;
    days += gd;
    var jalaliDays = days - 79;
    final cycle = jalaliDays ~/ 12053;
    jalaliDays %= 12053;
    var jy = 979 + 33 * cycle + 4 * (jalaliDays ~/ 1461);
    jalaliDays %= 1461;
    if (jalaliDays >= 366) {
      jy += (jalaliDays - 1) ~/ 365;
      jalaliDays = (jalaliDays - 1) % 365;
    }
    final jm = jalaliDays < 186
        ? 1 + (jalaliDays ~/ 31)
        : 7 + ((jalaliDays - 186) ~/ 30);
    final jd = 1 +
        (jalaliDays < 186 ? jalaliDays % 31 : (jalaliDays - 186) % 30);
    return JalaliDate(jy, jm, jd);
  }

  static bool _isGregorianLeap(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}
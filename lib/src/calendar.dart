/// تقویم شمسی (جلالی): تبدیل دقیق میلادی ↔ شمسی با پشتیبانی از سال کبیسه.
final class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const List<String> monthNames = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// هفتهٔ شمسی از شنبه شروع می‌شود.
  static const List<String> weekdayNames = <String>[
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

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
    final monthLengths = <int>[
      31,
      _isGregorianLeap(gy) ? 29 : 28,
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

  static JalaliDate fromDateTime(DateTime date) => fromGregorian(date);

  static JalaliDate today() => fromDateTime(DateTime.now());

  /// تعداد روزهای ماه شمسی؛ شش ماه اول ۳۱، پنج ماه بعد ۳۰ و اسفند
  /// بسته به کبیسه ۲۹ یا ۳۰ روز است.
  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    // اسفند: فاصلهٔ شروع اسفند تا شروع سال بعد.
    final DateTime start = JalaliDate(year, 12, 1).toGregorian();
    final DateTime nextYear = JalaliDate(year + 1, 1, 1).toGregorian();
    return nextYear.difference(start).inDays;
  }

  static bool isLeapYear(int year) => daysInMonth(year, 12) == 30;

  /// جابه‌جایی در ماه‌های شمسی (خنثی نسبت به کبیسه).
  JalaliDate addMonths(int months) {
    final int total = year * 12 + (month - 1) + months;
    final int targetYear = total ~/ 12;
    final int targetMonth = total % 12 + 1;
    final int maxDay = daysInMonth(targetYear, targetMonth);
    return JalaliDate(targetYear, targetMonth, day > maxDay ? maxDay : day);
  }

  /// ایندکس روز هفته با شروع از شنبه: شنبه = ۰ ... جمعه = ۶.
  int get weekdayIndex => (toGregorian().weekday + 1) % 7;

  String get monthName => monthNames[month - 1];
  String get weekdayName => weekdayNames[weekdayIndex];

  bool isSameDay(JalaliDate other) =>
      year == other.year && month == other.month && day == other.day;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}

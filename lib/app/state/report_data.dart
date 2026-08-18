import 'package:maliiiii/maliiiii.dart';

/// دسته‌ای از هزینه در بازه: نام، مبلغ و سهم نسبی.
final class CategorySlice {
  const CategorySlice({required this.category, required this.amount});

  final String category;
  final Money amount;

  double fraction(int totalMinorUnits) => totalMinorUnits <= 0
      ? 0
      : (amount.minorUnits / totalMinorUnits).clamp(0.0, 1.0);
}

/// گزارش ماه شمسی: جمع درآمد/هزینه/قسط و جریان نقدی واقعی.
final class JalaliMonthReport {
  const JalaliMonthReport({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.installments,
    required this.cashflow,
  });

  final DateTime start;
  final DateTime end;
  final Money income;
  final Money expense;
  final Money installments;
  final Money cashflow;
}

/// تفکیک هزینه‌ها بر اساس دسته در بازهٔ شمسی (از [start] تا [end]).
List<CategorySlice> categoryBreakdown(
  FinancialLedger ledger,
  DateTime start,
  DateTime end,
) {
  final Map<String, int> sums = <String, int>{};
  for (final LedgerTransaction transaction in ledger.transactions) {
    if (transaction.kind != TransactionKind.expense) continue;
    if (transaction.date.isBefore(start) || !transaction.date.isBefore(end)) {
      continue;
    }
    final String category = transaction.category ?? 'بدون دسته';
    sums[category] = (sums[category] ?? 0) + transaction.amount.minorUnits;
  }
  final List<CategorySlice> slices = <CategorySlice>[
    for (final MapEntry<String, int> entry in sums.entries)
      CategorySlice(category: entry.key, amount: Money(entry.value)),
  ]..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));
  return slices;
}

/// ساخت گزارش ماه شمسی از دفترکل؛ بازه از اول ماه شمسی تا اول ماه بعد.
JalaliMonthReport buildJalaliMonthReport(
  FinancialLedger ledger,
  JalaliDate month,
) {
  final DateTime start = JalaliDate(month.year, month.month, 1).toGregorian();
  final DateTime end = month.addMonths(1).toGregorian();
  Money sum(TransactionKind kind) => ledger.transactions
      .where(
        (item) =>
            item.kind == kind &&
            !item.date.isBefore(start) &&
            item.date.isBefore(end),
      )
      .fold(const Money(0), (total, item) => total + item.amount);
  final Money income = sum(TransactionKind.income);
  final Money expense = sum(TransactionKind.expense);
  final Money installments = sum(TransactionKind.installmentPayment);
  return JalaliMonthReport(
    start: start,
    end: end,
    income: income,
    expense: expense,
    installments: installments,
    cashflow: income - expense - installments,
  );
}

/// متن گزارش متنی فارسی برای نمایش/کپی؛ اعداد همگی فارسی و واحد تومان.
String buildTextReport({
  required JalaliMonthReport report,
  required JalaliDate month,
  required int healthScore,
  List<CategorySlice> categories = const <CategorySlice>[],
}) {
  final StringBuffer buffer = StringBuffer()
    ..writeln('گزارش مالی — ${month.monthName} ${toPersianDigits(month.year)}')
    ..writeln('درآمد: ${formatMinorUnits(report.income.minorUnits)}')
    ..writeln('هزینه: ${formatMinorUnits(report.expense.minorUnits)}')
    ..writeln('اقساط: ${formatMinorUnits(report.installments.minorUnits)}')
    ..writeln('جریان نقدی: ${formatMinorUnits(report.cashflow.minorUnits)}')
    ..writeln('امتیاز سلامت مالی: ${toPersianDigits(healthScore)} از ۱۰۰');
  if (categories.isNotEmpty) {
    buffer.writeln('سهم دسته‌ها:');
    for (final CategorySlice slice in categories) {
      buffer.writeln('- ${slice.category}: ${formatMinorUnits(slice.amount.minorUnits)}');
    }
  }
  return buffer.toString().trimRight();
}

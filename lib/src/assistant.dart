import 'engine.dart';
import 'models.dart';
import 'money.dart';
import 'number_format.dart';

/// لحن یک بینش مالی؛ رنگ و آیکون در لایهٔ UI از همین استفاده می‌شود.
enum InsightTone { good, warning, neutral, info }

/// یک بینش مالیِ تولیدشده از دفترکل.
final class Insight {
  const Insight({
    required this.title,
    required this.body,
    required this.tone,
    this.priority = 50,
  });

  final String title;
  final String body;
  final InsightTone tone;

  /// هرچه بیشتر باشد، بالاتر نمایش داده می‌شود.
  final int priority;
}

/// موتور بینش‌های مالی محلی (Local AI) — کاملاً قاعده‌محور و بدون وابستگی
/// بیرونی؛ همهٔ اعداد از دفترکل واقعی خوانده می‌شوند.
///
/// «هوش مصنوعی محلی» یعنی همین: تحلیل درون‌دستگاهیِ داده‌های کاربر، بدون
/// ارسال داده به بیرون. هر بینش یک [Insight] با عنوان، متن فارسی و لحن دارد.
List<Insight> buildInsights(
  FinancialLedger ledger, {
  required DateTime asOf,
  int horizonDays = 30,
}) {
  final List<Insight> insights = <Insight>[];

  final bool hasData = ledger.accounts.isNotEmpty ||
      ledger.transactions.isNotEmpty ||
      ledger.loans.isNotEmpty ||
      ledger.budgets.isNotEmpty ||
      ledger.goals.isNotEmpty;
  if (!hasData) {
    return insights;
  }

  // ── نمای کلی ────────────────────────────────────────────────────────────
  final Money balance = ledger.totalBalance();
  final Money available =
      ledger.availableMoney(asOf: asOf, horizonDays: horizonDays);
  insights.add(
    Insight(
      title: 'نمای کلی',
      body: 'موجودی کل شما ${formatMinorUnits(balance.minorUnits)} است و '
          'پول آزاد (پس از اقساط، بودجه و رزرو هدف‌ها) '
          '${formatMinorUnits(available.minorUnits)}.',
      tone: available.isNegative ? InsightTone.warning : InsightTone.info,
      priority: 10,
    ),
  );

  // ── سلامت مالی ─────────────────────────────────────────────────────────
  final FinancialHealthScore health = ledger.healthScore(asOf);
  if (health.value > 0 || ledger.transactions.isNotEmpty) {
    insights.add(
      Insight(
        title: 'امتیاز سلامت مالی',
        body: 'امتیاز شما ${toPersianDigits(health.value)} از ۱۰۰ است — '
            '${health.explanation}',
        tone: health.value >= 60
            ? InsightTone.good
            : health.value >= 40
                ? InsightTone.info
                : InsightTone.warning,
        priority: 20,
      ),
    );
  }

  // ── روند هزینهٔ این ماه نسبت به ماه قبل ─────────────────────────────────
  final DateTime monthStart = DateTime(asOf.year, asOf.month, 1);
  final DateTime prevStart = DateTime(asOf.year, asOf.month - 1, 1);
  final DateTime monthEnd = DateTime(asOf.year, asOf.month + 1, 1);
  final int currentExpense = monthlyExpense(ledger, monthStart, monthEnd);
  final int prevExpense = monthlyExpense(ledger, prevStart, monthStart);
  if (prevExpense > 0 && currentExpense > prevExpense * 1.25) {
    final int diff = currentExpense - prevExpense;
    insights.add(
      Insight(
        title: 'افزایش هزینه',
        body: 'هزینهٔ این ماه ${formatMinorUnits(diff)} بیشتر از ماه قبل '
            'است؛ اگر روند ادامه پیدا کند، بودجهٔ ماهانه تحت فشار قرار می‌گیرد.',
        tone: InsightTone.warning,
        priority: 45,
      ),
    );
  }

  // ── بزرگ‌ترین دستهٔ هزینه در ماه جاری ──────────────────────────────────
  final String? topCategory = topExpenseCategory(ledger, monthStart, monthEnd);
  if (topCategory != null) {
    insights.add(
      Insight(
        title: 'بزرگ‌ترین دستهٔ هزینه',
        body: 'بیشترین هزینهٔ این ماه در «$topCategory» ثبت شده است؛ '
            'مرور تراکنش‌های این دسته می‌تواند به صرفه‌جویی کمک کند.',
        tone: InsightTone.neutral,
        priority: 30,
      ),
    );
  }

  // ── بودجه‌های ردشده ────────────────────────────────────────────────────
  for (final Budget budget in ledger.budgets) {
    if (budget.endDate.isBefore(asOf)) continue;
    final int spent =
        spentOnCategory(ledger, budget.category, budget.startDate, budget.endDate);
    if (spent > budget.amount.minorUnits) {
      insights.add(
        Insight(
          title: 'بودجهٔ ردشده',
          body: 'بودجهٔ «${budget.name}» رد شده است: '
              '${formatMinorUnits(spent)} هزینه در برابر سقف '
              '${formatMinorUnits(budget.amount.minorUnits)}.',
          tone: InsightTone.warning,
          priority: 80,
        ),
      );
    }
  }

  // ── فشار بدهی ──────────────────────────────────────────────────────────
  final Money debt = ledger.outstandingDebt();
  if (debt.isPositive) {
    final bool heavy = debt.minorUnits > balance.minorUnits * 0.5;
    insights.add(
      Insight(
        title: 'بدهی فعال',
        body: heavy
            ? 'بدهی فعال شما ${formatMinorUnits(debt.minorUnits)} است و از '
                'نصف موجودی کل بیشتر است؛ پرداخت اقساط را در اولویت بگذار.'
            : 'بدهی فعال شما ${formatMinorUnits(debt.minorUnits)} است و '
                'تحت کنترل به نظر می‌رسد.',
        tone: heavy ? InsightTone.warning : InsightTone.info,
        priority: 70,
      ),
    );
  }

  // ── اقساط پیش‌رو و معوق ─────────────────────────────────────────────────
  final DateTime horizon =
      asOf.add(Duration(days: horizonDays));
  final List<Installment> upcoming =
      ledger.upcomingInstallments(asOf, horizon);
  if (upcoming.isNotEmpty) {
    final int totalDue = upcoming.fold<int>(
      0,
      (sum, installment) => sum + installment.remainingAmount.minorUnits,
    );
    final bool anyOverdue =
        ledger.loans.any(
              (Loan loan) => loan.installments.any(
                (Installment installment) =>
                    installment.statusAt(asOf) == InstallmentStatus.overdue,
              ),
            ) ||
        upcoming.any(
          (Installment installment) =>
              installment.statusAt(asOf) == InstallmentStatus.overdue,
        );
    insights.add(
      Insight(
        title: anyOverdue ? 'قسط معوق دارید' : 'اقساط پیش‌رو',
        body: '${toPersianDigits(upcoming.length)} قسط تا '
            '${toPersianDigits(horizonDays)} روز آینده'
            '${anyOverdue ? ' (شامل قسط معوق)' : ''} با مجموع '
            '${formatMinorUnits(totalDue)} پیش بینی می‌شود.',
        tone: anyOverdue ? InsightTone.warning : InsightTone.info,
        priority: 60,
      ),
    );
  }

  // ── اهداف نزدیک به سررسید ──────────────────────────────────────────────
  for (final Goal goal in ledger.goals) {
    final bool close = goal.deadline.isBefore(asOf.add(const Duration(days: 60)));
    if (close && goal.progress < 0.5) {
      insights.add(
        Insight(
          title: 'هدف در خطر',
          body: 'هدف «${goal.name}» کمتر از ۶۰ روز دیگر سررسید می‌شود اما '
              'فقط ${toPersianDigits((goal.progress * 100).round())}٪ '
              'پیشرفت دارد.',
          tone: InsightTone.warning,
          priority: 75,
        ),
      );
    }
  }

  // ── پیش‌بینی پایان ماه ─────────────────────────────────────────────────
  final Forecast? forecast = ledger.forecast(
    asOf: asOf,
    periodEnd: monthEnd,
  );
  if (forecast != null) {
    final bool negative =
        forecast.expectedBalance.minorUnits < 0;
    insights.add(
      Insight(
        title: 'پیش‌بینی پایان ماه',
        body: negative
            ? 'اگر روند فعلی ادامه یابد، موجودی شما تا پایان ماه منفی '
                '${formatMinorUnits(forecast.expectedBalance.minorUnits.abs())} '
                'خواهد شد؛ هزینه‌ها را همین حالا مدیریت کن.'
            : 'پیش‌بینی می‌شود موجودی شما تا پایان ماه '
                '${formatMinorUnits(forecast.expectedBalance.minorUnits)} باشد.',
        tone: negative ? InsightTone.warning : InsightTone.good,
        priority: 40,
      ),
    );
  }

  // ── منفی بودن موجودی کل ────────────────────────────────────────────────
  if (balance.isNegative) {
    insights.add(
      Insight(
        title: 'موجودی منفی',
        body: 'موجودی کل شما منفی است؛ اولین اولویت، رساندن حساب‌ها به '
            'عدد غیرمنفی است.',
        tone: InsightTone.warning,
        priority: 90,
      ),
    );
  }

  return insights..sort((a, b) => b.priority.compareTo(a.priority));
}

int monthlyExpense(FinancialLedger ledger, DateTime start, DateTime end) {
  int sum = 0;
  for (final LedgerTransaction transaction in ledger.transactions) {
    if (transaction.kind == TransactionKind.expense &&
        !transaction.date.isBefore(start) &&
        transaction.date.isBefore(end)) {
      sum += transaction.amount.minorUnits;
    }
  }
  return sum;
}

String? topExpenseCategory(
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
  String? best;
  int bestValue = 0;
  for (final MapEntry<String, int> entry in sums.entries) {
    if (entry.value > bestValue) {
      best = entry.key;
      bestValue = entry.value;
    }
  }
  return best;
}

int spentOnCategory(
  FinancialLedger ledger,
  String? category,
  DateTime start,
  DateTime end,
) {
  if (category == null) return 0;
  int sum = 0;
  for (final LedgerTransaction transaction in ledger.transactions) {
    if (transaction.kind == TransactionKind.expense &&
        transaction.category == category &&
        !transaction.date.isBefore(start) &&
        transaction.date.isBefore(end)) {
      sum += transaction.amount.minorUnits;
    }
  }
  return sum;
}

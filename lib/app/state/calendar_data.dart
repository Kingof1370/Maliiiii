import 'package:maliiiii/maliiiii.dart';

/// نوع رویداد نمایش‌داده‌شده در تقویم.
enum CalendarEventKind {
  income,
  expense,
  transfer,
  installmentPayment,
  installmentDue,
}

/// یک رویداد در یک روز خاص تقویم.
final class DayEvent {
  const DayEvent({
    required this.kind,
    required this.amount,
    required this.title,
    this.referenceId,
  });

  final CalendarEventKind kind;
  final Money amount;
  final String title;
  final String? referenceId;
}

/// رویدادهای یک روز شمسی از دفترکل.
///
/// انتقال فقط یک‌بار (سمت خروج) شمرده می‌شود تا دوباره‌شماری نشود؛ اقساط
/// پرداخت‌شده به‌عنوان «پرداخت قسط» و اقساط معوق به‌عنوان سررسید نمایش
/// داده می‌شوند.
List<DayEvent> eventsForDay(JalaliDate day, FinancialLedger ledger) {
  final DateTime start = day.toGregorian();
  final DateTime end = start.add(const Duration(days: 1));
  bool inDay(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  final List<DayEvent> events = <DayEvent>[];
  final Set<String> seenTransfers = <String>{};

  for (final LedgerTransaction transaction in ledger.transactions) {
    if (!inDay(transaction.date)) continue;
    switch (transaction.kind) {
      case TransactionKind.income:
        events.add(
          DayEvent(
            kind: CalendarEventKind.income,
            amount: transaction.amount,
            title: transaction.category ?? 'درآمد',
            referenceId: transaction.id,
          ),
        );
      case TransactionKind.expense:
        events.add(
          DayEvent(
            kind: CalendarEventKind.expense,
            amount: transaction.amount,
            title: transaction.category ?? 'هزینه',
            referenceId: transaction.id,
          ),
        );
      case TransactionKind.transferOut:
        if (seenTransfers.add(transaction.transferId ?? transaction.id)) {
          events.add(
            DayEvent(
              kind: CalendarEventKind.transfer,
              amount: transaction.amount,
              title: 'انتقال',
              referenceId: transaction.transferId,
            ),
          );
        }
      case TransactionKind.transferIn:
        // با سمت خروج همان انتقال شمارش شده است.
        break;
      case TransactionKind.installmentPayment:
        events.add(
          DayEvent(
            kind: CalendarEventKind.installmentPayment,
            amount: transaction.amount,
            title: 'پرداخت قسط',
            referenceId: transaction.referenceId,
          ),
        );
    }
  }

  for (final Loan loan in ledger.loans) {
    for (final Installment installment in loan.installments) {
      if (installment.remainingAmount.isPositive &&
          inDay(installment.dueDate)) {
        events.add(
          DayEvent(
            kind: CalendarEventKind.installmentDue,
            amount: installment.remainingAmount,
            title: 'قسط: ${loan.title}',
            referenceId: installment.id,
          ),
        );
      }
    }
  }

  return events;
}

/// وضعیت مالی روز: ۱ = مثبت، ۰ = خنثی، ۱- = منفی (فقط درآمد در برابر هزینه؛
/// انتقال و پرداخت قسط خنثی‌اند).
int dayStatus(List<DayEvent> events) {
  var net = 0;
  for (final DayEvent event in events) {
    if (event.kind == CalendarEventKind.income) net += event.amount.minorUnits;
    if (event.kind == CalendarEventKind.expense) net -= event.amount.minorUnits;
  }
  return net > 0 ? 1 : (net < 0 ? -1 : 0);
}

import 'package:maliiiii/maliiiii.dart';

/// قالب‌بندی تاریخ میلادی به شمسی برای نمایش در UI.
String formatJalaliDate(DateTime date) {
  final JalaliDate jalali = JalaliDate.fromDateTime(date);
  return '${toPersianDigits(jalali.day)} ${jalali.monthName} '
      '${toPersianDigits(jalali.year)}';
}

/// برچسب فارسی وضعیت قسط.
String installmentStatusLabel(InstallmentStatus status) => switch (status) {
      InstallmentStatus.upcoming => 'آینده',
      InstallmentStatus.due => 'سررسید نزدیک',
      InstallmentStatus.dueToday => 'سررسید امروز',
      InstallmentStatus.paid => 'پرداخت‌شده',
      InstallmentStatus.partiallyPaid => 'پرداخت جزئی',
      InstallmentStatus.overdue => 'عقب‌افتاده',
      InstallmentStatus.cancelled => 'لغوشده',
      InstallmentStatus.rescheduled => 'تعویض‌شده',
    };

/// برچسب فارسی وضعیت وام.
String loanStatusLabel(LoanStatus status) => switch (status) {
      LoanStatus.active => 'در حال بازپرداخت',
      LoanStatus.paidOff => 'تسویه‌شده',
      LoanStatus.archived => 'بایگانی',
    };

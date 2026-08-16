import 'money.dart';

enum AccountType {
  bank,
  card,
  cash,
  savings,
  wallet,
  investment,
}

enum TransactionKind {
  income,
  expense,
  transferOut,
  transferIn,
  installmentPayment,
}

enum LoanStatus { active, paidOff, archived }

enum InstallmentStatus {
  upcoming,
  due,
  dueToday,
  paid,
  partiallyPaid,
  overdue,
  cancelled,
  rescheduled,
}

enum GoalType { savings, purchase, income, debtReduction, investment, custom }

final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    this.notes = '',
  });

  final String id;
  final String name;
  final AccountType type;
  final Money openingBalance;
  final String notes;
}

final class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.kind,
    this.category,
    this.description = '',
    this.referenceId,
    this.transferId,
  });

  final String id;
  final String accountId;
  final Money amount;
  final DateTime date;
  final TransactionKind kind;
  final String? category;
  final String description;
  final String? referenceId;
  final String? transferId;
}

final class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.paidDate,
    required this.accountId,
    this.note = '',
  });

  final String id;
  final Money amount;
  final DateTime paidDate;
  final String accountId;
  final String note;
}

final class Installment {
  const Installment({
    required this.id,
    required this.loanId,
    required this.number,
    required this.dueDate,
    required this.totalAmount,
    this.principal,
    this.interest,
    this.fee,
    this.payments = const [],
    this.cancelled = false,
    this.rescheduled = false,
    this.notes = '',
  });

  final String id;
  final String loanId;
  final int number;
  final DateTime dueDate;
  final Money totalAmount;
  final Money? principal;
  final Money? interest;
  final Money? fee;
  final List<Payment> payments;
  final bool cancelled;
  final bool rescheduled;
  final String notes;

  Money get paidAmount => payments.fold(
        Money(0, currency: totalAmount.currency),
        (sum, payment) => sum + payment.amount,
      );

  Money get remainingAmount => totalAmount - paidAmount;

  InstallmentStatus statusAt(DateTime date) {
    if (cancelled) return InstallmentStatus.cancelled;
    if (rescheduled) return InstallmentStatus.rescheduled;
    if (remainingAmount.isZero) return InstallmentStatus.paid;
    if (paidAmount.isPositive) return InstallmentStatus.partiallyPaid;
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final today = DateTime(date.year, date.month, date.day);
    if (due.isBefore(today)) return InstallmentStatus.overdue;
    if (due == today) return InstallmentStatus.dueToday;
    if (due.difference(today).inDays <= 7) return InstallmentStatus.due;
    return InstallmentStatus.upcoming;
  }

  Installment withPayment(Payment payment) => Installment(
        id: id,
        loanId: loanId,
        number: number,
        dueDate: dueDate,
        totalAmount: totalAmount,
        principal: principal,
        interest: interest,
        fee: fee,
        payments: [...payments, payment],
        cancelled: cancelled,
        rescheduled: rescheduled,
        notes: notes,
      );
}

final class Loan {
  const Loan({
    required this.id,
    required this.title,
    required this.lender,
    required this.principal,
    required this.receivedAmount,
    required this.interest,
    required this.fees,
    required this.totalPayable,
    required this.startDate,
    this.status = LoanStatus.active,
    this.notes = '',
    this.installments = const [],
  });

  final String id;
  final String title;
  final String lender;
  final Money principal;
  final Money receivedAmount;
  final Money interest;
  final Money fees;
  final Money totalPayable;
  final DateTime startDate;
  final LoanStatus status;
  final String notes;
  final List<Installment> installments;

  Money get paidAmount => installments.fold(
        Money(0, currency: totalPayable.currency),
        (sum, item) => sum + item.paidAmount,
      );

  Money get remainingAmount => totalPayable - paidAmount;

  Loan withInstallment(Installment installment) => Loan(
        id: id,
        title: title,
        lender: lender,
        principal: principal,
        receivedAmount: receivedAmount,
        interest: interest,
        fees: fees,
        totalPayable: totalPayable,
        startDate: startDate,
        status: status,
        notes: notes,
        installments: [
          for (final item in installments)
            if (item.id == installment.id) installment else item,
        ],
      );
}

final class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.category,
  });

  final String id;
  final String name;
  final Money amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? category;
}

final class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.current,
    required this.deadline,
    this.priority = 3,
  });

  final String id;
  final String name;
  final GoalType type;
  final Money target;
  final Money current;
  final DateTime deadline;
  final int priority;

  double get progress {
    if (target.isZero) return 1;
    return (current.minorUnits / target.minorUnits).clamp(0, 1);
  }

  Money get remaining => (target - current).minorUnits < 0
      ? Money(0, currency: target.currency)
      : target - current;
}
import 'money.dart';

Map<String, Object?> _jsonMap(Object? value) =>
    (value as Map<Object?, Object?>?)?.cast<String, Object?>() ??
    const <String, Object?>{};

List<Object?> _jsonList(Object? value) =>
    (value as List<Object?>?) ?? const <Object?>[];

DateTime _parseDate(Object? value) =>
    DateTime.tryParse(value as String? ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

Money _parseMoney(Object? value) => Money.fromJson(_jsonMap(value));

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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance.toJson(),
        'notes': notes,
      };

  factory Account.fromJson(Map<String, Object?> json) => Account(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: AccountType.values.asNameMap()[json['type'] as String?] ??
            AccountType.cash,
        openingBalance: _parseMoney(json['openingBalance']),
        notes: json['notes'] as String? ?? '',
      );
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'accountId': accountId,
        'amount': amount.toJson(),
        'date': date.toIso8601String(),
        'kind': kind.name,
        'category': category,
        'description': description,
        'referenceId': referenceId,
        'transferId': transferId,
      };

  factory LedgerTransaction.fromJson(Map<String, Object?> json) =>
      LedgerTransaction(
        id: json['id'] as String? ?? '',
        accountId: json['accountId'] as String? ?? '',
        amount: _parseMoney(json['amount']),
        date: _parseDate(json['date']),
        kind: TransactionKind.values.asNameMap()[json['kind'] as String?] ??
            TransactionKind.expense,
        category: json['category'] as String?,
        description: json['description'] as String? ?? '',
        referenceId: json['referenceId'] as String?,
        transferId: json['transferId'] as String?,
      );
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'amount': amount.toJson(),
        'paidDate': paidDate.toIso8601String(),
        'accountId': accountId,
        'note': note,
      };

  factory Payment.fromJson(Map<String, Object?> json) => Payment(
        id: json['id'] as String? ?? '',
        amount: _parseMoney(json['amount']),
        paidDate: _parseDate(json['paidDate']),
        accountId: json['accountId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'loanId': loanId,
        'number': number,
        'dueDate': dueDate.toIso8601String(),
        'totalAmount': totalAmount.toJson(),
        'principal': principal?.toJson(),
        'interest': interest?.toJson(),
        'fee': fee?.toJson(),
        'payments': <Object?>[
          for (final Payment payment in payments) payment.toJson(),
        ],
        'cancelled': cancelled,
        'rescheduled': rescheduled,
        'notes': notes,
      };

  factory Installment.fromJson(Map<String, Object?> json) {
    Money? optionalMoney(Object? value) =>
        value == null ? null : _parseMoney(value);
    return Installment(
      id: json['id'] as String? ?? '',
      loanId: json['loanId'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      dueDate: _parseDate(json['dueDate']),
      totalAmount: _parseMoney(json['totalAmount']),
      principal: optionalMoney(json['principal']),
      interest: optionalMoney(json['interest']),
      fee: optionalMoney(json['fee']),
      payments: <Payment>[
        for (final Object? entry in _jsonList(json['payments']))
          Payment.fromJson(_jsonMap(entry)),
      ],
      cancelled: json['cancelled'] as bool? ?? false,
      rescheduled: json['rescheduled'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }
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

  Loan copyWithInstallments(List<Installment> installments) => Loan(
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
        installments: installments,
      );

  Loan copyWithStatus(LoanStatus status) => Loan(
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
        installments: installments,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'lender': lender,
        'principal': principal.toJson(),
        'receivedAmount': receivedAmount.toJson(),
        'interest': interest.toJson(),
        'fees': fees.toJson(),
        'totalPayable': totalPayable.toJson(),
        'startDate': startDate.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'installments': <Object?>[
          for (final Installment installment in installments)
            installment.toJson(),
        ],
      };

  factory Loan.fromJson(Map<String, Object?> json) => Loan(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        lender: json['lender'] as String? ?? '',
        principal: _parseMoney(json['principal']),
        receivedAmount: _parseMoney(json['receivedAmount']),
        interest: _parseMoney(json['interest']),
        fees: _parseMoney(json['fees']),
        totalPayable: _parseMoney(json['totalPayable']),
        startDate: _parseDate(json['startDate']),
        status: LoanStatus.values.asNameMap()[json['status'] as String?] ??
            LoanStatus.active,
        notes: json['notes'] as String? ?? '',
        installments: <Installment>[
          for (final Object? entry in _jsonList(json['installments']))
            Installment.fromJson(_jsonMap(entry)),
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'amount': amount.toJson(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'category': category,
      };

  factory Budget.fromJson(Map<String, Object?> json) => Budget(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        amount: _parseMoney(json['amount']),
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        category: json['category'] as String?,
      );
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

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'target': target.toJson(),
        'current': current.toJson(),
        'deadline': deadline.toIso8601String(),
        'priority': priority,
      };

  factory Goal.fromJson(Map<String, Object?> json) => Goal(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: GoalType.values.asNameMap()[json['type'] as String?] ??
            GoalType.custom,
        target: _parseMoney(json['target']),
        current: _parseMoney(json['current']),
        deadline: _parseDate(json['deadline']),
        priority: (json['priority'] as num?)?.toInt() ?? 3,
      );
}
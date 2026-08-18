import 'models.dart';
import 'money.dart';

final class FinancialValidationException implements Exception {
  FinancialValidationException(this.message);

  final String message;

  @override
  String toString() => 'FinancialValidationException: $message';
}

final class PaymentReceipt {
  const PaymentReceipt({
    required this.loan,
    required this.installment,
    required this.payment,
    required this.ledger,
  });

  final Loan loan;
  final Installment installment;
  final Payment payment;
  final FinancialLedger ledger;
}

final class MonthlySummary {
  const MonthlySummary({
    required this.income,
    required this.expense,
    required this.installmentPayments,
  });

  final Money income;
  final Money expense;
  final Money installmentPayments;

  Money get cashflow => income - expense - installmentPayments;
}

final class Forecast {
  const Forecast({
    required this.periodEnd,
    required this.expectedIncome,
    required this.expectedExpense,
    required this.expectedInstallments,
    required this.expectedBalance,
    required this.sampleDays,
  });

  final DateTime periodEnd;
  final Money expectedIncome;
  final Money expectedExpense;
  final Money expectedInstallments;
  final Money expectedBalance;
  final int sampleDays;
}

final class FinancialHealthScore {
  const FinancialHealthScore({
    required this.value,
    required this.savingsRate,
    required this.debtPressure,
    required this.budgetAdherence,
    required this.goalProgress,
    required this.explanation,
  });

  final int value;
  final double savingsRate;
  final double debtPressure;
  final double budgetAdherence;
  final double goalProgress;
  final String explanation;
}

/// Immutable source of truth for local financial calculations.
///
/// Installment payments are ledger entries of kind [TransactionKind
/// .installmentPayment], not expenses. This is the central double-counting
/// rule: reports can choose to show repayment separately without counting it
/// as a second expense.
final class FinancialLedger {
  const FinancialLedger({
    this.accounts = const [],
    this.transactions = const [],
    this.loans = const [],
    this.budgets = const [],
    this.goals = const [],
  });

  final List<Account> accounts;
  final List<LedgerTransaction> transactions;
  final List<Loan> loans;
  final List<Budget> budgets;
  final List<Goal> goals;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'accounts': <Object?>[
          for (final Account account in accounts) account.toJson(),
        ],
        'transactions': <Object?>[
          for (final LedgerTransaction transaction in transactions)
            transaction.toJson(),
        ],
        'loans': <Object?>[
          for (final Loan loan in loans) loan.toJson(),
        ],
        'budgets': <Object?>[
          for (final Budget budget in budgets) budget.toJson(),
        ],
        'goals': <Object?>[
          for (final Goal goal in goals) goal.toJson(),
        ],
      };

  factory FinancialLedger.fromJson(Map<String, Object?> json) {
    final Object? schema = json['schemaVersion'];
    if (schema is num && schema.toInt() > 1) {
      throw const FormatException('Unsupported ledger schema version.');
    }
    Map<String, Object?> entry(Object? value) =>
        (value as Map<Object?, Object?>).cast<String, Object?>();
    return FinancialLedger(
      accounts: <Account>[
        for (final Object? item
            in (json['accounts'] as List<Object?>? ?? const <Object?>[]))
          Account.fromJson(entry(item)),
      ],
      transactions: <LedgerTransaction>[
        for (final Object? item
            in (json['transactions'] as List<Object?>? ?? const <Object?>[]))
          LedgerTransaction.fromJson(entry(item)),
      ],
      loans: <Loan>[
        for (final Object? item
            in (json['loans'] as List<Object?>? ?? const <Object?>[]))
          Loan.fromJson(entry(item)),
      ],
      budgets: <Budget>[
        for (final Object? item
            in (json['budgets'] as List<Object?>? ?? const <Object?>[]))
          Budget.fromJson(entry(item)),
      ],
      goals: <Goal>[
        for (final Object? item
            in (json['goals'] as List<Object?>? ?? const <Object?>[]))
          Goal.fromJson(entry(item)),
      ],
    );
  }

  FinancialLedger copyWith({
    List<Account>? accounts,
    List<LedgerTransaction>? transactions,
    List<Loan>? loans,
    List<Budget>? budgets,
    List<Goal>? goals,
  }) =>
      FinancialLedger(
        accounts: accounts ?? this.accounts,
        transactions: transactions ?? this.transactions,
        loans: loans ?? this.loans,
        budgets: budgets ?? this.budgets,
        goals: goals ?? this.goals,
      );

  Money accountBalance(String accountId) {
    final account = accounts.firstWhere(
      (item) => item.id == accountId,
      orElse: () => throw FinancialValidationException(
        'Account not found: $accountId',
      ),
    );
    var balance = account.openingBalance;
    for (final transaction
        in transactions.where((item) => item.accountId == accountId)) {
      switch (transaction.kind) {
        case TransactionKind.income:
        case TransactionKind.transferIn:
          balance += transaction.amount;
        case TransactionKind.expense:
        case TransactionKind.transferOut:
        case TransactionKind.installmentPayment:
          balance -= transaction.amount;
      }
    }
    return balance;
  }

  Money totalBalance() {
    if (accounts.isEmpty) return const Money(0);
    return accounts
        .map((account) => accountBalance(account.id))
        .reduce((left, right) => left + right);
  }

  MonthlySummary monthlySummary(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    Money sum(TransactionKind kind) {
      final matching = transactions.where(
        (item) =>
            item.kind == kind &&
            !item.date.isBefore(start) &&
            item.date.isBefore(end),
      );
      return matching.fold(
        const Money(0),
        (total, item) => total + item.amount,
      );
    }

    return MonthlySummary(
      income: sum(TransactionKind.income),
      expense: sum(TransactionKind.expense),
      installmentPayments: sum(TransactionKind.installmentPayment),
    );
  }

  Money outstandingDebt() => loans
      .where((loan) => loan.status == LoanStatus.active)
      .fold(
        const Money(0),
        (sum, loan) => sum + loan.remainingAmount,
      );

  List<Installment> upcomingInstallments(
    DateTime from,
    DateTime through,
  ) =>
      [
        for (final loan in loans)
          for (final installment in loan.installments)
            if (!installment.dueDate.isBefore(from) &&
                installment.dueDate.isBefore(through) &&
                installment.remainingAmount.isPositive)
              installment,
      ]..sort((left, right) => left.dueDate.compareTo(right.dueDate));

  Money reservedForGoals() => goals.fold(
        const Money(0),
        (sum, goal) => sum + goal.remaining,
      );

  Money reservedForInstallments(DateTime from, DateTime through) =>
      upcomingInstallments(from, through).fold(
        const Money(0),
        (sum, installment) => sum + installment.remainingAmount,
      );

  /// Balance minus near-term installments, confirmed budgets, and goal
  /// reserves. The caller chooses the horizon; there is no hidden assumption.
  Money availableMoney({
    required DateTime asOf,
    int horizonDays = 30,
  }) {
    final horizon = asOf.add(Duration(days: horizonDays));
    final balance = totalBalance();
    final installments = reservedForInstallments(asOf, horizon);
    final budgets = budgetsDueBetween(asOf, horizon);
    return balance - installments - budgets - reservedForGoals();
  }

  Money budgetsDueBetween(DateTime from, DateTime through) => budgets
      .where(
        (budget) =>
            budget.startDate.isBefore(through) &&
            budget.endDate.isAfter(from),
      )
      .fold(
        const Money(0),
        (sum, budget) => sum + budget.amount,
      );

  FinancialLedger recordIncome({
    required String id,
    required String accountId,
    required Money amount,
    required DateTime date,
    String? category,
    String description = '',
  }) =>
      _appendTransaction(
        LedgerTransaction(
          id: id,
          accountId: accountId,
          amount: amount,
          date: date,
          kind: TransactionKind.income,
          category: category,
          description: description,
        ),
      );

  FinancialLedger recordExpense({
    required String id,
    required String accountId,
    required Money amount,
    required DateTime date,
    String? category,
    String description = '',
  }) =>
      _appendTransaction(
        LedgerTransaction(
          id: id,
          accountId: accountId,
          amount: amount,
          date: date,
          kind: TransactionKind.expense,
          category: category,
          description: description,
        ),
      );

  FinancialLedger recordTransfer({
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required DateTime date,
    String description = '',
  }) {
    if (fromAccountId == toAccountId) {
      throw FinancialValidationException(
        'Transfer accounts must be different.',
      );
    }
    if (accounts.every((item) => item.id != toAccountId)) {
      throw FinancialValidationException(
        'Transfer destination account not found.',
      );
    }
    if (accountBalance(fromAccountId) < amount) {
      throw FinancialValidationException(
        'Insufficient balance for transfer.',
      );
    }
    final outgoing = LedgerTransaction(
      id: '$transferId:out',
      accountId: fromAccountId,
      amount: amount,
      date: date,
      kind: TransactionKind.transferOut,
      description: description,
      transferId: transferId,
    );
    final incoming = LedgerTransaction(
      id: '$transferId:in',
      accountId: toAccountId,
      amount: amount,
      date: date,
      kind: TransactionKind.transferIn,
      description: description,
      transferId: transferId,
    );
    return copyWith(transactions: [...transactions, outgoing, incoming]);
  }

  FinancialLedger createAccount({
    required Account account,
  }) {
    if (accounts.any((item) => item.id == account.id)) {
      throw FinancialValidationException(
        'Account already exists: ${account.id}',
      );
    }
    return copyWith(accounts: [...accounts, account]);
  }

  FinancialLedger createLoan({required Loan loan}) {
    if (loans.any((item) => item.id == loan.id)) {
      throw FinancialValidationException(
        'Loan already exists: ${loan.id}',
      );
    }
    return copyWith(loans: [...loans, loan]);
  }

  /// افزودن قسط (نامنظم) به وام؛ چند قسط در یک روز مجاز است و شناسهٔ قسط‌ها
  /// باید یکتا باشد.
  FinancialLedger addInstallment({
    required String loanId,
    required Installment installment,
  }) {
    final Loan loan = _loanOrThrow(loanId);
    if (loan.installments.any((item) => item.id == installment.id)) {
      throw FinancialValidationException(
        'Installment already exists: ${installment.id}',
      );
    }
    if (installment.loanId != loanId) {
      throw FinancialValidationException(
        'Installment loan id does not match.',
      );
    }
    if (!installment.totalAmount.isPositive) {
      throw FinancialValidationException(
        'Installment total must be positive.',
      );
    }
    return _replaceLoan(
      loan.copyWithInstallments([
        ...loan.installments,
        installment,
      ]),
    );
  }

  /// تغییر سررسید قسط؛ با توافق طرفین انجام می‌شود و پرچم
  /// «تعویض‌شده» روی قسط ثبت می‌شود.
  FinancialLedger rescheduleInstallment({
    required String loanId,
    required String installmentId,
    required DateTime newDueDate,
  }) {
    final Loan loan = _loanOrThrow(loanId);
    final Installment installment = loan.installments.firstWhere(
      (item) => item.id == installmentId,
      orElse: () => throw FinancialValidationException(
        'Installment not found.',
      ),
    );
    if (installment.cancelled) {
      throw FinancialValidationException(
        'Cancelled installment cannot be rescheduled.',
      );
    }
    final Installment updated = Installment(
      id: installment.id,
      loanId: installment.loanId,
      number: installment.number,
      dueDate: newDueDate,
      totalAmount: installment.totalAmount,
      principal: installment.principal,
      interest: installment.interest,
      fee: installment.fee,
      payments: installment.payments,
      cancelled: installment.cancelled,
      rescheduled: true,
      notes: installment.notes,
    );
    return _replaceLoan(loan.withInstallment(updated));
  }

  /// لغو قسط؛ فقط وقتی پرداختی نداشته باشد مجاز است.
  FinancialLedger cancelInstallment({
    required String loanId,
    required String installmentId,
  }) {
    final Loan loan = _loanOrThrow(loanId);
    final Installment installment = loan.installments.firstWhere(
      (item) => item.id == installmentId,
      orElse: () => throw FinancialValidationException(
        'Installment not found.',
      ),
    );
    if (installment.paidAmount.isPositive) {
      throw FinancialValidationException(
        'Paid installment cannot be cancelled.',
      );
    }
    final Installment updated = Installment(
      id: installment.id,
      loanId: installment.loanId,
      number: installment.number,
      dueDate: installment.dueDate,
      totalAmount: installment.totalAmount,
      principal: installment.principal,
      interest: installment.interest,
      fee: installment.fee,
      payments: installment.payments,
      cancelled: true,
      rescheduled: installment.rescheduled,
      notes: installment.notes,
    );
    return _replaceLoan(loan.withInstallment(updated));
  }

  /// تسویهٔ وام: فقط وقتی باقی‌مانده صفر باشد.
  FinancialLedger completeLoan({required String loanId}) {
    final Loan loan = _loanOrThrow(loanId);
    if (!loan.remainingAmount.isZero) {
      throw FinancialValidationException(
        'Loan has remaining balance.',
      );
    }
    return _replaceLoan(loan.copyWithStatus(LoanStatus.paidOff));
  }

  /// بایگانی وام (بدون تغییر در موجودی‌ها).
  FinancialLedger archiveLoan({required String loanId}) {
    final Loan loan = _loanOrThrow(loanId);
    return _replaceLoan(loan.copyWithStatus(LoanStatus.archived));
  }

  Loan _loanOrThrow(String loanId) => loans.firstWhere(
        (item) => item.id == loanId,
        orElse: () => throw FinancialValidationException('Loan not found.'),
      );

  FinancialLedger _replaceLoan(Loan updated) => copyWith(
        loans: [
          for (final item in loans)
            if (item.id == updated.id) updated else item,
        ],
      );

  PaymentReceipt recordInstallmentPayment({
    required String paymentId,
    required String ledgerEntryId,
    required String loanId,
    required String installmentId,
    required String accountId,
    required Money amount,
    required DateTime paidDate,
    String note = '',
  }) {
    final loan = loans.firstWhere(
      (item) => item.id == loanId,
      orElse: () => throw FinancialValidationException('Loan not found.'),
    );
    final installment = loan.installments.firstWhere(
      (item) => item.id == installmentId,
      orElse: () => throw FinancialValidationException(
        'Installment not found.',
      ),
    );
    if (installment.remainingAmount < amount) {
      throw FinancialValidationException(
        'Payment exceeds installment remaining amount.',
      );
    }
    if (accountBalance(accountId) < amount) {
      throw FinancialValidationException(
        'Insufficient balance for installment payment.',
      );
    }
    final payment = Payment(
      id: paymentId,
      amount: amount,
      paidDate: paidDate,
      accountId: accountId,
      note: note,
    );
    final updatedInstallment = installment.withPayment(payment);
    final updatedLoan = loan.withInstallment(updatedInstallment);
    final entry = LedgerTransaction(
      id: ledgerEntryId,
      accountId: accountId,
      amount: amount,
      date: paidDate,
      kind: TransactionKind.installmentPayment,
      description: note,
      referenceId: installmentId,
    );
    final updatedLoans = [
      for (final item in loans)
        if (item.id == loanId) updatedLoan else item,
    ];
    final updatedLedger = copyWith(
      loans: updatedLoans,
      transactions: [...transactions, entry],
    );
    return PaymentReceipt(
      loan: updatedLoan,
      installment: updatedInstallment,
      payment: payment,
      ledger: updatedLedger,
    );
  }

  Forecast? forecast({
    required DateTime asOf,
    required DateTime periodEnd,
    int minimumSampleDays = 7,
  }) {
    final historyStart = asOf.subtract(const Duration(days: 90));
    final sample = transactions
        .where(
          (item) =>
              !item.date.isBefore(historyStart) &&
              !item.date.isAfter(asOf),
        )
        .toList();
    if (sample.isEmpty) return null;
    final sampleDays = asOf.difference(historyStart).inDays + 1;
    if (sampleDays < minimumSampleDays) return null;
    Money sum(TransactionKind kind) => sample
        .where((item) => item.kind == kind)
        .fold(const Money(0), (total, item) => total + item.amount);
    final days = periodEnd.difference(asOf).inDays.clamp(0, 366);
    final expectedIncome = _scaleDaily(sum(TransactionKind.income), days, sampleDays);
    final expectedExpense = _scaleDaily(sum(TransactionKind.expense), days, sampleDays);
    final expectedInstallments =
        _scaleDaily(sum(TransactionKind.installmentPayment), days, sampleDays);
    return Forecast(
      periodEnd: periodEnd,
      expectedIncome: expectedIncome,
      expectedExpense: expectedExpense,
      expectedInstallments: expectedInstallments,
      expectedBalance: totalBalance() +
          expectedIncome -
          expectedExpense -
          expectedInstallments,
      sampleDays: sampleDays,
    );
  }

  FinancialHealthScore healthScore(DateTime month) {
    final summary = monthlySummary(month);
    final income = summary.income.minorUnits;
    final outflow =
        summary.expense.minorUnits + summary.installmentPayments.minorUnits;
    final savingsRate = income <= 0
        ? 0.0
        : ((income - outflow) / income).clamp(0, 1).toDouble();
    final debt = outstandingDebt().minorUnits;
    final debtPressure =
        income <= 0 ? 1.0 : (debt / income).clamp(0, 1).toDouble();
    final budgetAdherence = _budgetAdherence(month, summary.expense);
    final goalProgress = goals.isEmpty
        ? 1.0
        : goals.map((goal) => goal.progress).reduce((a, b) => a + b) /
            goals.length;
    final score = (savingsRate * 30 +
            (1 - debtPressure) * 25 +
            budgetAdherence * 25 +
            goalProgress * 20)
        .round()
        .clamp(0, 100)
        .toInt();
    return FinancialHealthScore(
      value: score,
      savingsRate: savingsRate,
      debtPressure: debtPressure,
      budgetAdherence: budgetAdherence,
      goalProgress: goalProgress,
      explanation:
          'امتیاز بر اساس پس‌انداز ۳۰٪، فشار بدهی ۲۵٪، پایبندی به بودجه ۲۵٪ و پیشرفت اهداف ۲۰٪ محاسبه شده است.',
    );
  }

  FinancialLedger _appendTransaction(LedgerTransaction transaction) {
    if (accounts.every((account) => account.id != transaction.accountId)) {
      throw FinancialValidationException('Account not found.');
    }
    return copyWith(transactions: [...transactions, transaction]);
  }

  double _budgetAdherence(DateTime month, Money expenses) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final budget = budgets
        .where(
          (item) =>
              item.category == null &&
              item.startDate.isBefore(end) &&
              item.endDate.isAfter(start),
        )
        .fold(0, (sum, item) => sum + item.amount.minorUnits);
    if (budget == 0) return expenses.isZero ? 1 : 0;
    final adherence =
        1 - (expenses.minorUnits - budget).clamp(0, budget) / budget;
    return adherence.clamp(0, 1).toDouble();
  }

  Money _scaleDaily(Money total, int days, int sampleDays) => Money(
        (total.minorUnits * days / sampleDays).round(),
        currency: total.currency,
      );
}
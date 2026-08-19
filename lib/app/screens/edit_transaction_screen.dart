import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../widgets/transaction_form.dart';

/// ویرایش تراکنش درآمد/هزینه؛ فقط برای تراکنش‌های عادی باز می‌شود.
class EditTransactionScreen extends StatelessWidget {
  const EditTransactionScreen({super.key, required this.transaction});

  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final bool income = transaction.kind == TransactionKind.income;
    return Scaffold(
      appBar: AppBar(title: Text(income ? 'ویرایش درآمد' : 'ویرایش هزینه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TransactionForm(
            kind: income
                ? TransactionFormKind.income
                : TransactionFormKind.expense,
            initialAccountId: transaction.accountId,
            initialAmount: transaction.amount.minorUnits,
            initialCategory: transaction.category,
            initialDescription: transaction.description,
            submitLabel: 'ذخیرهٔ تغییرات',
            onDone: (accountId, amount, category, description) async {
              final AccountController controller = AccountScope.of(context);
              await controller.updateTransaction(
                id: transaction.id,
                accountId: accountId,
                amountMinorUnits: amount,
                date: transaction.date,
                category: category,
                description: description,
              );
            },
          ),
        ],
      ),
    );
  }
}

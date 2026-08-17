import 'package:flutter/material.dart';

import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../widgets/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key, required this.income});

  final bool income;

  @override
  Widget build(BuildContext context) {
    final AccountController controller = AccountScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(income ? 'درآمد جدید' : 'هزینهٔ جدید'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TransactionForm(
            kind: income
                ? TransactionFormKind.income
                : TransactionFormKind.expense,
            onDone: (accountId, amount, category, description) async {
              final String id =
                  'trx-${DateTime.now().microsecondsSinceEpoch}';
              if (income) {
                await controller.recordIncome(
                  id: id,
                  accountId: accountId,
                  amountMinorUnits: amount,
                  date: DateTime.now(),
                  category: category,
                  description: description,
                );
              } else {
                await controller.recordExpense(
                  id: id,
                  accountId: accountId,
                  amountMinorUnits: amount,
                  date: DateTime.now(),
                  category: category,
                  description: description,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

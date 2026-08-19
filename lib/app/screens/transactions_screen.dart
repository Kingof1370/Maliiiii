import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../state/ledger_scope.dart';
import '../theme/app_theme.dart';
import 'edit_transaction_screen.dart';

/// تاریخچهٔ کامل تراکنش‌ها؛ هر ردیف قابل ویرایش/حذف است (انتقال و قسط
/// با قواعد خودشان مدیریت می‌شوند).
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final AccountController accountController = AccountScope.of(context);
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    final List<LedgerTransaction> txs = <LedgerTransaction>[
      ...ledger.transactions,
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچهٔ تراکنش‌ها')),
      body: txs.isEmpty
          ? Center(
              child: Text(
                'هنوز تراکنشی ثبت نشده است.',
                style: TextStyle(color: palette.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              itemCount: txs.length,
              separatorBuilder: (_, __) =>
                  Divider(color: palette.divider, height: 1),
              itemBuilder: (BuildContext context, int index) {
                final LedgerTransaction tx = txs[index];
                return _TransactionRow(
                  transaction: tx,
                  accountName: _accountName(accountController, tx.accountId),
                  onTap: () =>
                      _showActions(context, accountController, tx),
                );
              },
            ),
    );
  }

  String _accountName(AccountController controller, String accountId) {
    for (final Account account in controller.accounts) {
      if (account.id == accountId) return account.name;
    }
    return '—';
  }
}

void _showActions(
  BuildContext context,
  AccountController controller,
  LedgerTransaction tx,
) {
  final AppPalette palette = context.appPalette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(
              _rowTitle(tx),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(_kindLabel(tx.kind)),
          ),
          const Divider(height: 1),
          if (tx.kind == TransactionKind.income ||
              tx.kind == TransactionKind.expense) ...<Widget>[
            ListTile(
              key: const Key('tx-action-edit'),
              leading: Icon(Icons.edit_outlined, color: palette.primary),
              title: const Text('ویرایش'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditTransactionScreen(transaction: tx),
                  ),
                );
              },
            ),
            ListTile(
              key: const Key('tx-action-delete'),
              leading: Icon(Icons.delete_outline_rounded,
                  color: palette.danger),
              title: Text('حذف', style: TextStyle(color: palette.danger)),
              onTap: () =>
                  _confirmDelete(context, sheetContext, controller, tx),
            ),
          ] else if (tx.kind == TransactionKind.transferOut ||
              tx.kind == TransactionKind.transferIn) ...<Widget>[
            ListTile(
              key: const Key('tx-action-delete'),
              leading: Icon(Icons.delete_outline_rounded,
                  color: palette.danger),
              title: Text('حذف انتقال', style: TextStyle(color: palette.danger)),
              subtitle: const Text('هر دو طرف انتقال حذف می‌شوند'),
              onTap: () =>
                  _confirmDelete(context, sheetContext, controller, tx),
            ),
          ] else
            ListTile(
              leading:
                  Icon(Icons.lock_outline_rounded, color: palette.textMuted),
              title: const Text('پرداخت قسط از صفحهٔ وام مدیریت می‌شود'),
            ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  BuildContext sheetContext,
  AccountController controller,
  LedgerTransaction tx,
) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف تراکنش؟'),
      content: Text(
        tx.transferId != null
            ? 'این انتقال و طرف مقابل آن حذف می‌شوند.'
            : 'این تراکنش برای همیشه حذف می‌شود.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          key: const Key('tx-delete-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (ok ?? false) {
    try {
      await controller.deleteTransaction(tx.id);
      if (sheetContext.mounted) Navigator.pop(sheetContext);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

String _rowTitle(LedgerTransaction tx) {
  final String? category = tx.category;
  if (category != null && category.isNotEmpty) return category;
  if (tx.description.isNotEmpty) return tx.description;
  return _kindLabel(tx.kind);
}

String _kindLabel(TransactionKind kind) => switch (kind) {
      TransactionKind.income => 'درآمد',
      TransactionKind.expense => 'هزینه',
      TransactionKind.transferOut || TransactionKind.transferIn => 'انتقال',
      TransactionKind.installmentPayment => 'قسط',
    };

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.accountName,
    required this.onTap,
  });

  final LedgerTransaction transaction;
  final String accountName;
  final VoidCallback onTap;

  IconData get _icon => switch (transaction.kind) {
        TransactionKind.income => Icons.add_circle_outline,
        TransactionKind.expense => Icons.remove_circle_outline,
        TransactionKind.transferOut || TransactionKind.transferIn =>
          Icons.swap_horiz_rounded,
        TransactionKind.installmentPayment => Icons.payments_rounded,
      };

  bool get _positive =>
      transaction.kind == TransactionKind.income ||
      transaction.kind == TransactionKind.transferIn;

  String _amount() {
    final String digits =
        formatMinorUnits(transaction.amount.minorUnits, suffix: '');
    return _positive ? '+$digits' : '−$digits';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final JalaliDate j = JalaliDate.fromDateTime(transaction.date);
    final String date =
        '${j.day} ${j.monthName} ${toPersianDigits(j.year)}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(_icon, size: 20, color: palette.primary),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _rowTitle(transaction),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$accountName · $date',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Text(
              _amount(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _positive ? palette.positive : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

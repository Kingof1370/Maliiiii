import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_controller.dart';
import '../state/account_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountController controller = AccountScope.of(context);
    final List<Account> accounts = controller.accounts;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'حساب‌ها',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              // دکمهٔ افزودن حساب
              IconButton.filled(
                key: const Key('add-account-button'),
                tooltip: 'حساب جدید',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddAccountScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (accounts.isEmpty)
            const _EmptyAccounts()
          else
            for (final Account account in accounts)
              _AccountCard(
                key: Key('account-card-${account.id}'),
                account: account,
                balance: controller.balanceOf(account.id),
                onEdit: () => _showAccountSheet(context, controller, account),
              ),
          const SizedBox(height: AppDimensions.spaceLg),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        children: <Widget>[
          Icon(Icons.account_balance_wallet_outlined,
              size: 52, color: palette.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'هنوز حسابی ثبت نکرده‌ای',
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            'بانک، کارت، نقدی، پس‌انداز، کیف پول یا سرمایه‌گذاری',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.account,
    required this.balance,
    required this.onEdit,
  });

  final Account account;
  final Money balance;
  final VoidCallback onEdit;

  static const Map<AccountType, IconData> _icons = <AccountType, IconData>{
    AccountType.bank: Icons.account_balance_rounded,
    AccountType.card: Icons.credit_card_rounded,
    AccountType.cash: Icons.payments_rounded,
    AccountType.savings: Icons.savings_rounded,
    AccountType.wallet: Icons.wallet_rounded,
    AccountType.investment: Icons.trending_up_rounded,
  };

  static const Map<AccountType, String> _labels = <AccountType, String>{
    AccountType.bank: 'بانک',
    AccountType.card: 'کارت',
    AccountType.cash: 'نقدی',
    AccountType.savings: 'پس‌انداز',
    AccountType.wallet: 'کیف پول',
    AccountType.investment: 'سرمایه‌گذاری',
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final String balanceText = formatMinorUnits(
      balance.minorUnits,
      suffix: '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: PremiumCard(
        elevation: PremiumElevation.raised,
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(_icons[account.type], color: palette.primary),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    account.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _labels[account.type] ?? '',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            IconButton(
              key: Key('account-edit-${account.id}'),
              tooltip: 'مدیریت حساب',
              onPressed: onEdit,
              icon: const Icon(Icons.more_vert_rounded),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  balanceText,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'تومان',
                  style: TextStyle(color: palette.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// برگهٔ مدیریت حساب: ویرایش نام/نوع/یادداشت یا حذف حساب (با محافظ).
void _showAccountSheet(
  BuildContext context,
  AccountController controller,
  Account account,
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
              account.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(formatMinorUnits(
              controller.balanceOf(account.id).minorUnits,
              suffix: '',
            )),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('account-action-edit'),
            leading: Icon(Icons.edit_outlined, color: palette.primary),
            title: const Text('ویرایش حساب'),
            onTap: () {
              Navigator.pop(sheetContext);
              _showEditAccountDialog(context, controller, account);
            },
          ),
          ListTile(
            key: const Key('account-action-delete'),
            leading: Icon(Icons.delete_outline_rounded, color: palette.danger),
            title: Text('حذف حساب', style: TextStyle(color: palette.danger)),
            onTap: () async {
              Navigator.pop(sheetContext);
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('حذف حساب؟'),
                  content: const Text('فقط حساب‌های بدون تراکنش قابل حذف‌اند.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('انصراف'),
                    ),
                    FilledButton(
                      key: const Key('account-delete-confirm'),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );
              if (ok ?? false) {
                try {
                  await controller.deleteAccount(account.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _showEditAccountDialog(
  BuildContext context,
  AccountController controller,
  Account account,
) async {
  final TextEditingController name =
      TextEditingController(text: account.name);
  final TextEditingController notes =
      TextEditingController(text: account.notes);
  AccountType type = account.type;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('ویرایش حساب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                key: const Key('account-edit-name'),
                controller: name,
                decoration: const InputDecoration(labelText: 'نام حساب'),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              DropdownButtonFormField<AccountType>(
                key: const Key('account-edit-type'),
                initialValue: type,
                items: <DropdownMenuItem<AccountType>>[
                  for (final AccountType value in AccountType.values)
                    DropdownMenuItem<AccountType>(
                      value: value,
                      child: Text(_typeLabel(value)),
                    ),
                ],
                onChanged: (AccountType? value) {
                  if (value != null) setState(() => type = value);
                },
                decoration: const InputDecoration(labelText: 'نوع'),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              TextField(
                key: const Key('account-edit-notes'),
                controller: notes,
                decoration: const InputDecoration(labelText: 'یادداشت'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            key: const Key('account-edit-save'),
            onPressed: () async {
              await controller.updateAccount(
                id: account.id,
                name: name.text.trim().isEmpty ? null : name.text.trim(),
                type: type,
                notes: notes.text.trim(),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );
  // به‌دلیل انیمیشن خروج دیالوگ، controllerها را dispose نمی‌کنیم؛
  // GC آن‌ها را پس از جدا شدن کامل از درخت ویجت جمع می‌کند.
}

String _typeLabel(AccountType type) => switch (type) {
      AccountType.bank => 'بانک',
      AccountType.card => 'کارت',
      AccountType.cash => 'نقدی',
      AccountType.savings => 'پس‌انداز',
      AccountType.wallet => 'کیف پول',
      AccountType.investment => 'سرمایه‌گذاری',
    };

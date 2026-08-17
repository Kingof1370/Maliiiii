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
                account: account,
                balance: controller.balanceOf(account.id),
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
  const _AccountCard({required this.account, required this.balance});

  final Account account;
  final Money balance;

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

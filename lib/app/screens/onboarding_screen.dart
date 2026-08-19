import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';

import '../branding.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/account_scope.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_backdrop.dart';
import '../widgets/premium_card.dart';
import '../widgets/profile_form.dart';

/// معرفی کوتاه و زیبا؛ ثبت نام و نام خانوادگی ضروری است و کاربر می‌تواند
/// حساب اول (نقدی/بانک و…) را همین‌جا بسازد تا بلافاصله «پول آزاد» داشته باشد.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _accountName =
      TextEditingController(text: 'نقدی');
  final TextEditingController _balance = TextEditingController();
  AccountType _accountType = AccountType.cash;

  @override
  void dispose() {
    _accountName.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _finish(UserProfile profile) async {
    await ProfileScope.of(context).createProfile(profile);
    final String name = _accountName.text.trim();
    final int balance = int.tryParse(_balance.text.replaceAll(',', '')) ?? 0;
    if (name.isEmpty) return;
    await AccountScope.of(context).addAccount(
      id: 'acc-onboarding-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: _accountType,
      openingMinorUnits: balance < 0 ? 0 : balance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Scaffold(
      body: PremiumBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            children: <Widget>[
              const SizedBox(height: AppDimensions.spaceLg),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        palette.primary,
                        palette.gold.withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Center(
                child: Text(
                  Branding.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              Center(
                child: Text(
                  'سلام 👋 به مالیار خوش آمدی',
                  style: TextStyle(color: palette.textSecondary, fontSize: 14),
                ),
              ),
              Center(
                child: Text(
                  Branding.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              ProfileForm(
                submitLabel: 'شروع',
                onDone: _finish,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _InitialAccountCard(
                nameController: _accountName,
                balanceController: _balance,
                type: _accountType,
                onTypeChanged: (AccountType value) =>
                    setState(() => _accountType = value),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              const DeveloperFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// کارت «حساب اول»: نام، موجودی اولیه و نوع حساب — اختیاری اما پیش‌فرض
/// «نقدی» آماده است تا کاربر بدون حساب بی‌وجود نماند.
class _InitialAccountCard extends StatelessWidget {
  const _InitialAccountCard({
    required this.nameController,
    required this.balanceController,
    required this.type,
    required this.onTypeChanged,
  });

  final TextEditingController nameController;
  final TextEditingController balanceController;
  final AccountType type;
  final ValueChanged<AccountType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet_outlined,
                  color: palette.primary, size: 20),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                'حساب اول',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'می‌توانید بعداً در «حساب‌ها» حساب بیشتری بسازید.',
            style: TextStyle(color: palette.textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          TextFormField(
            key: const Key('initial-account-name'),
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'نام حساب',
              prefixIcon: Icon(Icons.label_outline_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          TextFormField(
            key: const Key('initial-account-balance'),
            controller: balanceController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'موجودی اولیه (تومان)',
              prefixIcon: Icon(Icons.payments_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          DropdownButtonFormField<AccountType>(
            key: const Key('initial-account-type'),
            initialValue: type,
            decoration: const InputDecoration(
              labelText: 'نوع حساب',
              prefixIcon: Icon(Icons.account_balance_outlined),
              counterText: '',
            ),
            items: <DropdownMenuItem<AccountType>>[
              for (final AccountType value in AccountType.values)
                DropdownMenuItem<AccountType>(
                  value: value,
                  child: Text(_typeLabel(value)),
                ),
            ],
            onChanged: (AccountType? value) {
              if (value != null) onTypeChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

String _typeLabel(AccountType type) => switch (type) {
      AccountType.bank => 'بانک',
      AccountType.card => 'کارت',
      AccountType.cash => 'نقدی',
      AccountType.savings => 'پس‌انداز',
      AccountType.wallet => 'کیف پول',
      AccountType.investment => 'سرمایه‌گذاری',
    };

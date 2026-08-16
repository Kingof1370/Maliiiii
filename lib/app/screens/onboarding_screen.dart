import 'package:flutter/material.dart';

import '../branding.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_backdrop.dart';
import '../widgets/profile_form.dart';

/// معرفی کوتاه و زیبا؛ ثبت نام و نام خانوادگی ضروری است.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
                onDone: (profile) => ProfileScope.of(context).createProfile(profile),
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

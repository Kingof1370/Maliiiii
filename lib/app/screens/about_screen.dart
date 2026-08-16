import 'package:flutter/material.dart';

import '../branding.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';

/// صفحهٔ درباره: نام، نسخه، حریم خصوصی، مجوزها و امضای طلایی توسعه‌دهنده.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Scaffold(
      appBar: AppBar(title: const Text(FaStrings.about)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          const SizedBox(height: AppDimensions.spaceSm),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    palette.primary,
                    palette.gold.withValues(alpha: 0.75),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Center(
            child: Text(
              Branding.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Center(
            child: Text(
              Branding.tagline,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Center(
            child: Text(
              'نسخهٔ ${Branding.version}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoRow(
                  icon: Icons.lock_outline_rounded,
                  title: FaStrings.privacy,
                  value: FaStrings.privacyNote,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spaceSm,
                  ),
                  child: Divider(color: palette.divider),
                ),
                _InfoRow(
                  icon: Icons.description_outlined,
                  title: FaStrings.licenses,
                  value: 'Flutter و Vazirmatn تحت مجوزهای متن‌باز خود.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXl),
          const DeveloperFooter(),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: palette.primary),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

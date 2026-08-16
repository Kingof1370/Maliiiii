import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'about_screen.dart';

/// تنظیمات: حالت نمایش، درباره و امضای توسعه‌دهنده.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'تنظیمات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PremiumCard(
            child: Column(
              children: <Widget>[
                _SettingRow(
                  icon: Icons.brightness_6_outlined,
                  title: FaStrings.theme,
                  value: _themeLabel(themeMode),
                  onTap: () => _showThemeSheet(context),
                ),
                _SettingRow(
                  icon: Icons.info_outline_rounded,
                  title: FaStrings.about,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(
            FaStrings.privacyNote,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          const DeveloperFooter(),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final AppPalette palette = context.appPalette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: themeMode,
          onChanged: (value) {
            onThemeModeChanged(value!);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.brightness_auto_outlined),
                title: Text('سیستم'),
                trailing: Radio<ThemeMode>(value: ThemeMode.system),
              ),
              const ListTile(
                leading: Icon(Icons.light_mode_outlined),
                title: Text(FaStrings.lightMode),
                trailing: Radio<ThemeMode>(value: ThemeMode.light),
              ),
              const ListTile(
                leading: Icon(Icons.dark_mode_outlined),
                title: Text(FaStrings.darkMode),
                trailing: Radio<ThemeMode>(value: ThemeMode.dark),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'سیستم',
        ThemeMode.light => FaStrings.lightMode,
        ThemeMode.dark => FaStrings.darkMode,
      };
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return ListTile(
      leading: Icon(icon, color: palette.primary),
      title: Text(title),
      trailing: value != null
          ? Text(value!, style: TextStyle(color: palette.textMuted))
          : Icon(Icons.chevron_left_rounded, color: palette.textMuted),
      onTap: onTap,
    );
  }
}

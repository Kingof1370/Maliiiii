import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maliiiii/maliiiii.dart';
import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../localization/fa_strings.dart';
import '../state/profile_controller.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_footer.dart';
import '../widgets/premium_card.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_categories_screen.dart';


/// تنظیمات: پروفایل، امنیت (PIN)، حالت نمایش، لحن اعلان، AI و درباره.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final ProfileController controller = ProfileScope.of(context);
    final UserProfile? profile = controller.profile;

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
          _ProfileCard(profile: profile),
          const SizedBox(height: AppDimensions.spaceMd),
          PremiumCard(
            child: Column(
              children: <Widget>[
                _SettingRow(
                  icon: Icons.brightness_6_outlined,
                  title: FaStrings.theme,
                  value: (profile?.displayMode ?? DisplayMode.system).label,
                  onTap: () => _showThemeSheet(context, controller),
                ),
                Divider(color: palette.divider, height: 1),
                _SettingRow(
                  icon: Icons.notifications_outlined,
                  title: 'لحن اعلان‌ها',
                  value: (profile?.tone ?? NotificationTone.friendly).label,
                  onTap: () => _showToneSheet(context, controller),
                ),
                Divider(color: palette.divider, height: 1),
                _SettingRow(
                  icon: Icons.category_outlined,
                  title: 'دسته‌های سفارشی',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ManageCategoriesScreen(),
                    ),
                  ),
                ),
                Divider(color: palette.divider, height: 1),
                _SettingRow(
                  icon: Icons.auto_awesome_rounded,
                  title: 'دستیار هوشمند محلی',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AssistantScreen(),
                    ),
                  ),
                ),
                Divider(color: palette.divider, height: 1),
                SwitchListTile(
                  key: const Key('settings-ai-switch'),
                  secondary: Icon(Icons.auto_awesome_rounded,
                      color: palette.gold),
                  title: const Text('نمایش بینش‌ها'),
                  subtitle: const Text('تحلیل محلی داده‌ها — بدون ارسال به بیرون'),
                  value: profile?.aiEnabled ?? false,
                  onChanged: (bool value) => _updateProfile(
                    controller,
                    (controller.profile ?? profile)!.copyWith(aiEnabled: value),
                  ),
                ),
                Divider(color: palette.divider, height: 1),
                _PinTile(controller: controller),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          PremiumCard(
            child: Column(
              children: <Widget>[
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

  void _updateProfile(ProfileController controller, UserProfile profile) {
    controller.updateProfile(profile);
  }

  void _showThemeSheet(BuildContext context, ProfileController controller) {
    final UserProfile current = controller.profile!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: RadioGroup<DisplayMode>(
          groupValue: current.displayMode,
          onChanged: (DisplayMode? value) {
            if (value != null) {
              _updateProfile(controller, current.copyWith(displayMode: value));
            }
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final DisplayMode mode in DisplayMode.values)
                ListTile(
                  leading: Icon(_displayIcon(mode)),
                  title: Text(mode.label),
                  trailing: Radio<DisplayMode>(value: mode),
                ),
              const SizedBox(height: AppDimensions.spaceSm),
            ],
          ),
        ),
      ),
    );
  }

  IconData _displayIcon(DisplayMode mode) => switch (mode) {
        DisplayMode.system => Icons.brightness_auto_outlined,
        DisplayMode.light => Icons.light_mode_outlined,
        DisplayMode.dark => Icons.dark_mode_outlined,
      };

  void _showToneSheet(BuildContext context, ProfileController controller) {
    final UserProfile current = controller.profile!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final NotificationTone tone in NotificationTone.values)
              ListTile(
                leading: Icon(
                  tone == current.tone
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: tone == current.tone
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(tone.label),
                onTap: () {
                  _updateProfile(controller, current.copyWith(tone: tone));
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: AppDimensions.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final String name = profile?.fullName ?? '—';
    final String nickname = profile?.nickname ?? '';

    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
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
            ),
            child: Text(
              profile == null ? '؟' : name.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (nickname.isNotEmpty)
                  Text(
                    '@$nickname',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                Text(
                  (profile?.currency ?? ProfileCurrency.irt).label,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EditProfileScreen(),
              ),
            ),
            child: const Text('ویرایش'),
          ),
        ],
      ),
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final bool hasPin = controller.profile?.hasPin ?? false;

    return Column(
      children: <Widget>[
        if (hasPin)
          ListTile(
            leading: Icon(Icons.lock_outline_rounded, color: palette.primary),
            title: const Text('تغییر رمز PIN'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  PinSetupDialog(controller: controller, replace: true),
            ),
          )
        else
          ListTile(
            key: const Key('settings-set-pin'),
            leading: Icon(Icons.lock_outline_rounded, color: palette.primary),
            title: const Text('فعال‌سازی قفل برنامه'),
            subtitle: const Text('رمز ۴ رقمی برای ورود به برنامه'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  PinSetupDialog(controller: controller, replace: false),
            ),
          ),
        if (hasPin)
          ListTile(
            key: const Key('settings-remove-pin'),
            leading: Icon(Icons.lock_open_rounded, color: palette.danger),
            title:
                Text('حذف قفل برنامه', style: TextStyle(color: palette.danger)),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => _confirmRemovePin(context),
          ),
      ],
    );
  }

  Future<void> _confirmRemovePin(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف قفل برنامه؟'),
        content: const Text('بعد از حذف، برای ورود رمز لازم نیست.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            key: const Key('pin-remove-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm ?? false) {
      controller.removePin();
    }
  }
}

/// دیالوگ تنظیم/تغییر رمز PIN.
///
/// کنترلرهای متن متعلق به خود این State هستند و در [dispose] آزاد می‌شوند؛
/// بنابراین بعد از بسته‌شدن دیالوگ هیچ کنترلر آزادشده‌ای استفاده نمی‌شود.
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({
    super.key,
    required this.controller,
    required this.replace,
  });

  final ProfileController controller;
  final bool replace;

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _save() {
    if (_first.text.length != 4) {
      setState(() => _error = 'رمز باید ۴ رقم باشد.');
      return;
    }
    if (_first.text != _second.text) {
      setState(() => _error = 'رمزها یکسان نیستند.');
      return;
    }
    widget.controller.setPin(_first.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.replace ? 'تغییر رمز PIN' : 'تنظیم رمز PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const Key('pin-set-input1'),
              controller: _first,
              obscureText: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              maxLength: 4,
              style: const TextStyle(fontSize: 22, letterSpacing: 10),
              decoration: InputDecoration(
                labelText: 'رمز ۴ رقمی',
                counterText: '',
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            TextField(
              key: const Key('pin-set-input2'),
              controller: _second,
              obscureText: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              maxLength: 4,
              style: const TextStyle(fontSize: 22, letterSpacing: 10),
              decoration: const InputDecoration(
                labelText: 'تکرار رمز',
                counterText: '',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          key: const Key('pin-set-save'),
          onPressed: _save,
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
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

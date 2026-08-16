import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../theme/app_theme.dart';
import 'premium_card.dart';

/// فرم پروفایل مشترک بین Onboarding و ویرایش؛ خروجی [UserProfile] معتبر.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.onDone,
    required this.submitLabel,
    this.initial,
  });

  final void Function(UserProfile profile) onDone;
  final String submitLabel;
  final UserProfile? initial;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _nickname;
  late ProfileCurrency _currency;
  late NotificationTone _tone;
  late DisplayMode _displayMode;
  late bool _aiEnabled;

  @override
  void initState() {
    super.initState();
    final UserProfile? initial = widget.initial;
    _firstName = TextEditingController(text: initial?.firstName ?? '');
    _lastName = TextEditingController(text: initial?.lastName ?? '');
    _nickname = TextEditingController(text: initial?.nickname ?? '');
    _currency = initial?.currency ?? ProfileCurrency.irt;
    _tone = initial?.tone ?? NotificationTone.friendly;
    _displayMode = initial?.displayMode ?? DisplayMode.system;
    _aiEnabled = initial?.aiEnabled ?? false;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nickname.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final String firstName = _firstName.text.trim();
    final String lastName = _lastName.text.trim();
    final String nickname = _nickname.text.trim();

    final UserProfile result;
    if (widget.initial == null) {
      result = UserProfile.create(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname.isEmpty ? null : nickname,
        currency: _currency,
        tone: _tone,
        displayMode: _displayMode,
        aiEnabled: _aiEnabled,
      );
    } else {
      final UserProfile base = widget.initial!;
      result = base.copyWith(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname.isEmpty ? null : nickname,
        clearNickname: nickname.isEmpty,
        currency: _currency,
        tone: _tone,
        displayMode: _displayMode,
        aiEnabled: _aiEnabled,
      );
    }
    widget.onDone(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final ThemeData theme = Theme.of(context);

    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Label(palette: palette, text: 'نام و نام خانوادگی'),
            const SizedBox(height: AppDimensions.spaceSm),
            TextFormField(
              key: const Key('field-first-name'),
              controller: _firstName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'نام',
                hintText: 'مثلاً علی',
                prefixIcon: Icon(Icons.person_outline_rounded),
                counterText: '',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'نام نمی‌تواند خالی باشد.'
                      : null,
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            TextFormField(
              key: const Key('field-last-name'),
              controller: _lastName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'نام خانوادگی',
                hintText: 'مثلاً بهمنی',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'نام خانوادگی نمی‌تواند خالی باشد.'
                      : null,
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            TextFormField(
              key: const Key('field-nickname'),
              controller: _nickname,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'نام مستعار (اختیاری)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _Label(palette: palette, text: 'واحد پول'),
            const SizedBox(height: AppDimensions.spaceSm),
            SegmentedButton<ProfileCurrency>(
              segments: const <ButtonSegment<ProfileCurrency>>[
                ButtonSegment<ProfileCurrency>(
                  value: ProfileCurrency.irt,
                  label: Text('تومان'),
                  icon: Icon(Icons.paid_outlined),
                ),
                ButtonSegment<ProfileCurrency>(
                  value: ProfileCurrency.irl,
                  label: Text('ریال'),
                ),
              ],
              selected: <ProfileCurrency>{_currency},
              showSelectedIcon: false,
              onSelectionChanged: (Set<ProfileCurrency> selection) =>
                  setState(() => _currency = selection.first),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _Label(palette: palette, text: 'لحن اعلان‌ها'),
            const SizedBox(height: AppDimensions.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final NotificationTone tone in NotificationTone.values)
                  ChoiceChip(
                    label: Text(tone.label),
                    selected: _tone == tone,
                    onSelected: (_) => setState(() => _tone = tone),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _Label(palette: palette, text: 'حالت نمایش'),
            const SizedBox(height: AppDimensions.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final DisplayMode mode in DisplayMode.values)
                  ChoiceChip(
                    label: Text(mode.label),
                    selected: _displayMode == mode,
                    onSelected: (_) => setState(() => _displayMode = mode),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            SwitchListTile(
              key: const Key('switch-ai'),
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.auto_awesome_rounded,
                  color: palette.gold),
              title: const Text('هوش مصنوعی محلی'),
              subtitle: const Text('اختیاری — در فاز Local AI متصل می‌شود'),
              value: _aiEnabled,
              onChanged: (bool value) => setState(() => _aiEnabled = value),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('profile-form-submit'),
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  widget.submitLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.palette, required this.text});

  final AppPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

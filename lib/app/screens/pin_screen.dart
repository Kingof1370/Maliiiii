import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/profile_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_backdrop.dart';

/// قفل برنامه: ورود با رمز ۴ رقمی. بعد از ۳ تلاش ناموفق مجدداً امتحان می‌کند
/// (هیچ محدودیت قفل‌شدن سختی در این فاز اعمال نمی‌شود).
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    final bool ok = ProfileScope.of(context).verifyPin(_pin.text);
    if (ok) {
      ProfileScope.of(context).unlock();
    } else {
      setState(() {
        _error = 'رمز اشتباه است';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;

    return Scaffold(
      body: PremiumBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primarySoft,
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: palette.primary, size: 36),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text(
                  'قفل برنامه',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  'برای ورود، رمز ۴ رقمی را وارد کنید',
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                TextField(
                  key: const Key('pin-unlock-input'),
                  controller: _pin,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 12),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    errorText: _error,
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('pin-unlock-submit'),
                    onPressed: _submit,
                    child: const Text('ورود'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

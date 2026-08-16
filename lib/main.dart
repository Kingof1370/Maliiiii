import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/branding.dart';
import 'app/data/profile_repository.dart';
import 'app/data/profile_store.dart';
import 'app/design/app_colors.dart';
import 'app/screens/onboarding_screen.dart';
import 'app/screens/pin_screen.dart';
import 'app/shell/main_shell.dart';
import 'app/state/profile_controller.dart';
import 'app/state/profile_scope.dart';
import 'app/theme/app_theme.dart';
import 'src/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory docs = await getApplicationDocumentsDirectory();
  final ProfileStore store =
      FileProfileStore(File('${docs.path}/user_profile.json'));
  runApp(MaliiiiiApp(profileStore: store));
}

/// نقطهٔ ورود اپلیکیشن.
///
/// مسیر اجرا بر اساس وضعیت پروفایل:
/// بارگذاری ← (نیاز به معرفی) onboarding ← (قفل PIN) ← پوستهٔ اصلی.
class MaliiiiiApp extends StatefulWidget {
  const MaliiiiiApp({super.key, required this.profileStore});

  final ProfileStore profileStore;

  @override
  State<MaliiiiiApp> createState() => _MaliiiiiAppState();
}

class _MaliiiiiAppState extends State<MaliiiiiApp> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(ProfileRepository(widget.profileStore));
    _controller.init();
  }

  ThemeMode _themeMode() => switch (
      _controller.profile?.displayMode ?? DisplayMode.system) {
        DisplayMode.system => ThemeMode.system,
        DisplayMode.light => ThemeMode.light,
        DisplayMode.dark => ThemeMode.dark,
      };

  Widget _home() => switch (_controller.status) {
        ProfileStatus.loading => const _SplashScreen(),
        ProfileStatus.needsOnboarding => const OnboardingScreen(),
        ProfileStatus.locked => const PinScreen(),
        ProfileStatus.ready => const MainShell(),
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) {
        return ProfileScope(
          controller: _controller,
          child: MaterialApp(
            title: Branding.appName,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: _themeMode(),
            home: _home(),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Scaffold(
      body: Center(
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
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

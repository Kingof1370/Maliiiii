import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'app/branding.dart';
import 'app/data/ledger_repository.dart';
import 'app/data/ledger_store.dart';
import 'app/data/profile_repository.dart';
import 'app/data/profile_store.dart';
import 'app/design/app_colors.dart';
import 'app/screens/onboarding_screen.dart';
import 'app/screens/pin_screen.dart';
import 'app/shell/main_shell.dart';
import 'app/state/account_controller.dart';
import 'app/state/account_scope.dart';
import 'app/state/budget_controller.dart';
import 'app/state/budget_scope.dart';
import 'app/state/category_controller.dart';
import 'app/state/category_scope.dart';
import 'app/state/goal_controller.dart';
import 'app/state/goal_scope.dart';
import 'app/state/ledger_controller.dart';
import 'app/state/ledger_scope.dart';
import 'app/state/loan_controller.dart';
import 'app/state/loan_scope.dart';
import 'app/state/note_controller.dart';
import 'app/state/note_scope.dart';
import 'app/state/profile_controller.dart';
import 'app/state/profile_scope.dart';
import 'app/theme/app_theme.dart';
import 'src/profile.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory docs = await getApplicationDocumentsDirectory();
  final ProfileStore profileStore =
      FileProfileStore(File('${docs.path}/user_profile.json'));
  final LedgerStore ledgerStore =
      FileLedgerStore(File('${docs.path}/ledger.json'));
  runApp(MaliiiiiApp(profileStore: profileStore, ledgerStore: ledgerStore));
}

/// نقطهٔ ورود اپلیکیشن.
///
/// مسیر اجرا بر اساس وضعیت پروفایل:
/// بارگذاری ← (نیاز به معرفی) onboarding ← (قفل PIN) ← پوستهٔ اصلی.
/// دفترکل مالی به‌صورت موازی بارگذاری و از طریق [LedgerScope] در دسترس
/// همهٔ صفحات قرار می‌گیرد.
class MaliiiiiApp extends StatefulWidget {
  const MaliiiiiApp({
    super.key,
    required this.profileStore,
    required this.ledgerStore,
  });

  final ProfileStore profileStore;
  final LedgerStore ledgerStore;

  @override
  State<MaliiiiiApp> createState() => _MaliiiiiAppState();
}

class _MaliiiiiAppState extends State<MaliiiiiApp> {
  late final ProfileController _profileController;
  late final LedgerController _ledgerController;
  late final AccountController _accountController;
  late final LoanController _loanController;
  late final BudgetController _budgetController;
  late final GoalController _goalController;
  late final CategoryController _categoryController;
  late final NoteController _noteController;

  @override
  void initState() {
    super.initState();
    _profileController =
        ProfileController(ProfileRepository(widget.profileStore));
    _ledgerController = LedgerController(LedgerRepository(widget.ledgerStore));
    _accountController = AccountController(_ledgerController);
    _loanController = LoanController(_ledgerController);
    _budgetController = BudgetController(_ledgerController);
    _goalController = GoalController(_ledgerController);
    _categoryController = CategoryController(_ledgerController);
    _noteController = NoteController(_ledgerController);
    _profileController.init();
    _ledgerController.init();
  }

  ThemeMode _themeMode() => switch (
      _profileController.profile?.displayMode ?? DisplayMode.system) {
        DisplayMode.system => ThemeMode.system,
        DisplayMode.light => ThemeMode.light,
        DisplayMode.dark => ThemeMode.dark,
      };

  Widget _home() => switch (_profileController.status) {
        ProfileStatus.loading => const _SplashScreen(),
        ProfileStatus.needsOnboarding => const OnboardingScreen(),
        ProfileStatus.locked => const PinScreen(),
        ProfileStatus.ready => const MainShell(),
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        <Listenable>[_profileController, _ledgerController],
      ),
      builder: (BuildContext context, _) {
        return ProfileScope(
          controller: _profileController,
          child: LedgerScope(
            controller: _ledgerController,
            child: NoteScope(
              controller: _noteController,
              child: CategoryScope(
              controller: _categoryController,
              child: BudgetScope(
              controller: _budgetController,
              child: LoanScope(
                controller: _loanController,
                child: GoalScope(
                controller: _goalController,
                child: AccountScope(
                controller: _accountController,
                child: MaterialApp(
                  title: Branding.appName,
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(Brightness.light),
                  darkTheme: buildAppTheme(Brightness.dark),
                  themeMode: _themeMode(),
                  home: _home(),
                ),
              ),
              ),
              ),
              ),
            ),
          ),
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

import 'package:flutter/material.dart';

import 'app/branding.dart';
import 'app/shell/main_shell.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const MaliiiiiApp());
}

/// نقطهٔ ورود اپلیکیشن.
///
/// تم روشن/تاریک هر دو ساخته می‌شوند و حالت از [ThemeMode.system] شروع
/// می‌شود؛ کاربر می‌تواند از صفحهٔ تنظیمات آن را تغییر دهد.
class MaliiiiiApp extends StatefulWidget {
  const MaliiiiiApp({super.key});

  @override
  State<MaliiiiiApp> createState() => _MaliiiiiAppState();
}

class _MaliiiiiAppState extends State<MaliiiiiApp> {
  ThemeMode _mode = ThemeMode.system;

  void _selectMode(ThemeMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Branding.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: _mode,
      home: MainShell(
        themeMode: _mode,
        onThemeModeChanged: _selectMode,
      ),
    );
  }
}

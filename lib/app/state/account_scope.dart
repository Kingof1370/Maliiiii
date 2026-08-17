import 'package:flutter/widgets.dart';

import 'account_controller.dart';

/// دسترسی سلسله‌مراتبی به [AccountController].
class AccountScope extends InheritedNotifier<AccountController> {
  const AccountScope({
    super.key,
    required AccountController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccountController of(BuildContext context) {
    final AccountScope? scope =
        context.dependOnInheritedWidgetOfExactType<AccountScope>();
    assert(scope != null, 'AccountScope not found in widget tree');
    return scope!.notifier!;
  }
}

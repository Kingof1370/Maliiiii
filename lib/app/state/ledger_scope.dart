import 'package:flutter/widgets.dart';

import 'ledger_controller.dart';

/// دسترسی سلسله‌مراتبی به [LedgerController] برای همهٔ صفحات.
class LedgerScope extends InheritedNotifier<LedgerController> {
  const LedgerScope({
    super.key,
    required LedgerController controller,
    required super.child,
  }) : super(notifier: controller);

  static LedgerController of(BuildContext context) {
    final LedgerScope? scope =
        context.dependOnInheritedWidgetOfExactType<LedgerScope>();
    assert(scope != null, 'LedgerScope not found in widget tree');
    return scope!.notifier!;
  }
}

import 'package:flutter/widgets.dart';

import 'loan_controller.dart';

/// دسترسی سلسله‌مراتبی به [LoanController].
class LoanScope extends InheritedNotifier<LoanController> {
  const LoanScope({
    super.key,
    required LoanController controller,
    required super.child,
  }) : super(notifier: controller);

  static LoanController of(BuildContext context) {
    final LoanScope? scope =
        context.dependOnInheritedWidgetOfExactType<LoanScope>();
    assert(scope != null, 'LoanScope not found in widget tree');
    return scope!.notifier!;
  }
}

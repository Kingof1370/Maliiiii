import 'package:flutter/widgets.dart';

import 'budget_controller.dart';

/// دسترسی سلسله‌مراتبی به [BudgetController].
class BudgetScope extends InheritedNotifier<BudgetController> {
  const BudgetScope({
    super.key,
    required BudgetController controller,
    required super.child,
  }) : super(notifier: controller);

  static BudgetController of(BuildContext context) {
    final BudgetScope? scope =
        context.dependOnInheritedWidgetOfExactType<BudgetScope>();
    assert(scope != null, 'BudgetScope not found in widget tree');
    return scope!.notifier!;
  }
}

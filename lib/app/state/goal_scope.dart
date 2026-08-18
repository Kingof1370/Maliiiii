import 'package:flutter/widgets.dart';

import 'goal_controller.dart';

/// دسترسی سلسله‌مراتبی به [GoalController].
class GoalScope extends InheritedNotifier<GoalController> {
  const GoalScope({
    super.key,
    required GoalController controller,
    required super.child,
  }) : super(notifier: controller);

  static GoalController of(BuildContext context) {
    final GoalScope? scope =
        context.dependOnInheritedWidgetOfExactType<GoalScope>();
    assert(scope != null, 'GoalScope not found in widget tree');
    return scope!.notifier!;
  }
}

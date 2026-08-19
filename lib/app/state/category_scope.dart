import 'package:flutter/widgets.dart';

import 'category_controller.dart';

/// دسترسی سلسله‌مراتبی به [CategoryController].
class CategoryScope extends InheritedNotifier<CategoryController> {
  const CategoryScope({
    super.key,
    required CategoryController controller,
    required super.child,
  }) : super(notifier: controller);

  static CategoryController of(BuildContext context) {
    final CategoryScope? scope =
        context.dependOnInheritedWidgetOfExactType<CategoryScope>();
    assert(scope != null, 'CategoryScope not found in widget tree');
    return scope!.notifier!;
  }
}

import 'package:flutter/widgets.dart';

import 'profile_controller.dart';

/// دسترسی سلسله‌مراتبی به [ProfileController] برای همهٔ صفحات.
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    super.key,
    required ProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProfileController of(BuildContext context) {
    final ProfileScope? scope =
        context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'ProfileScope not found in widget tree');
    return scope!.notifier!;
  }
}

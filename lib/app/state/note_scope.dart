import 'package:flutter/widgets.dart';

import 'note_controller.dart';

/// دسترسی سلسله‌مراتبی به [NoteController].
class NoteScope extends InheritedNotifier<NoteController> {
  const NoteScope({
    super.key,
    required NoteController controller,
    required super.child,
  }) : super(notifier: controller);

  static NoteController of(BuildContext context) {
    final NoteScope? scope =
        context.dependOnInheritedWidgetOfExactType<NoteScope>();
    assert(scope != null, 'NoteScope not found in widget tree');
    return scope!.notifier!;
  }
}

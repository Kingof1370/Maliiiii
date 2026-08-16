import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// اسکرول قطعی داخل صفحه‌ای از نوع [screenType] تا دیده‌شدن [target].
/// برای ListViewهایی که با children ساخته می‌شوند، همهٔ آیتم‌ها در درخت
/// هستند و scrollUntilVisible همیشه به هدف می‌رسد.
Future<void> scrollToIn(
  WidgetTester tester,
  Finder target,
  Type screenType, {
  double delta = 200,
}) async {
  final Finder scrollable = find
      .descendant(
        of: find.byType(screenType),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, delta, scrollable: scrollable);
  await tester.pumpAndSettle();
}

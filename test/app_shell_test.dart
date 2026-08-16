import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/data/profile_store.dart';
import 'package:maliiiii/app/screens/onboarding_screen.dart';
import 'package:maliiiii/app/screens/settings_screen.dart';
import 'package:maliiiii/main.dart';
import 'package:maliiiii/maliiiii.dart';

import 'memory_profile_store.dart';
import 'test_helpers.dart';

UserProfile seededProfile() =>
    UserProfile.create(firstName: 'علی', lastName: 'بهمنی');

Future<void> pumpApp(WidgetTester tester, ProfileStore store) async {
  await tester.pumpWidget(MaliiiiiApp(profileStore: store));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('seeded profile renders Farsi home with real name',
      (WidgetTester tester) async {
    final MemoryProfileStore store = MemoryProfileStore(seededProfile());
    await pumpApp(tester, store);

    expect(find.text('سلام علی 👋'), findsOneWidget);
    expect(find.text('موجودی کل'), findsOneWidget);
    expect(find.text('پول آزاد واقعی'), findsOneWidget);

    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('علی بهمنی'), findsOneWidget);

    await scrollToIn(
      tester,
      find.textContaining('توسعه‌دهنده: علی بهمنی'),
      SettingsScreen,
    );
    expect(find.textContaining('توسعه‌دهنده: علی بهمنی'), findsOneWidget);
  });

  testWidgets('empty profile shows onboarding and requires names',
      (WidgetTester tester) async {
    final MemoryProfileStore store = MemoryProfileStore();
    await pumpApp(tester, store);

    expect(find.text('سلام 👋 به مالیار خوش آمدی'), findsOneWidget);
    expect(find.byKey(const Key('field-first-name')), findsOneWidget);

    // دکمهٔ شروع در پایین فرم است؛ ابتدا اسکرول می‌کنیم
    await scrollToIn(
      tester,
      find.byKey(const Key('profile-form-submit')),
      OnboardingScreen,
    );
    await tester.tap(find.byKey(const Key('profile-form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('نام نمی‌تواند خالی باشد.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field-first-name')), 'علی');
    await tester.enterText(find.byKey(const Key('field-last-name')), 'بهمنی');
    await scrollToIn(
      tester,
      find.byKey(const Key('profile-form-submit')),
      OnboardingScreen,
    );
    await tester.tap(find.byKey(const Key('profile-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('سلام علی 👋'), findsOneWidget);
  });

  testWidgets('navigation bar switches between sections',
      (WidgetTester tester) async {
    final MemoryProfileStore store = MemoryProfileStore(seededProfile());
    await pumpApp(tester, store);

    await tester.tap(find.text('وام‌ها و بدهی‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز وامی ثبت نشده است'), findsOneWidget);

    await tester.tap(find.text('گزارش‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز داده‌ای برای گزارش نیست'), findsOneWidget);
  });
}

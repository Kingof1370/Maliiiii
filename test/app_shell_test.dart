import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/main.dart';

void main() {
  testWidgets('app renders Farsi UI and developer signature',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaliiiiiApp());
    await tester.pumpAndSettle();

    // عناصر بالای داشبورد (همه در viewport اولیه قابل مشاهده‌اند)
    expect(find.text('سلام 👋'), findsOneWidget);
    expect(find.text('موجودی کل'), findsOneWidget);
    expect(find.text('پول آزاد واقعی'), findsOneWidget);

    // امضای توسعه‌دهنده در صفحهٔ تنظیمات (بالای صفحه و بدون نیاز به اسکرول)
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('درباره'), findsOneWidget);
    expect(find.textContaining('توسعه‌دهنده: علی بهمنی'), findsOneWidget);
  });

  testWidgets('navigation bar switches between sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaliiiiiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('وام‌ها و بدهی‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز وامی ثبت نشده است'), findsOneWidget);

    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('درباره'), findsOneWidget);
    expect(find.text('حالت نمایش'), findsOneWidget);
  });
}

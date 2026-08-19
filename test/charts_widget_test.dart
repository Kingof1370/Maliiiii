import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliiiii/app/design/app_colors.dart';
import 'package:maliiiii/app/state/report_data.dart';
import 'package:maliiiii/app/widgets/report_charts.dart';
import 'package:maliiiii/maliiiii.dart';

void main() {
  final AppPalette palette = AppPalette.light;

  List<CategorySlice> slices() => <CategorySlice>[
        const CategorySlice(category: 'خوراک', amount: Money(600_000)),
        const CategorySlice(category: 'مسکن', amount: Money(300_000)),
        const CategorySlice(category: 'سایر', amount: Money(100_000)),
      ];

  testWidgets('donut chart renders slices, count and total', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DonutChart(slices: slices(), palette: palette)),
    ));
    expect(find.byType(DonutChart), findsOneWidget);
    expect(find.text('۳ دسته'), findsOneWidget);
    expect(find.textContaining('تومان'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('donut chart shows empty state without expenses', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DonutChart(slices: const <CategorySlice>[], palette: palette),
      ),
    ));
    expect(find.textContaining('ثبت نشده'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trend line chart renders six points without errors',
      (tester) async {
    final List<TrendPoint> points = <TrendPoint>[
      for (int i = 0; i < 6; i++)
        TrendPoint(
          label: 'ماه ${toPersianDigits(i + 1)}',
          income: Money((i + 1) * 100_000),
          expense: Money(i * 50_000),
        ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrendLineChart(points: points, palette: palette),
      ),
    ));
    expect(find.byType(TrendLineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trend line chart tolerates all-zero data', (tester) async {
    final List<TrendPoint> points = <TrendPoint>[
      for (int i = 0; i < 6; i++)
        const TrendPoint(label: '', income: Money(0), expense: Money(0)),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrendLineChart(points: points, palette: palette),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}

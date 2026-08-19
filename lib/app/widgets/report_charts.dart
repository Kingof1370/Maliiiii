import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../state/report_data.dart';

/// رنگ‌های متمایز برای بخش‌های نمودار دوناتی (چرخهٔ تکراری).
const List<int> _chartColors = <int>[
  0xFF3B5BDB,
  0xFF16A34A,
  0xFFDF8500,
  0xFFDC2626,
  0xFF2563EB,
  0xFF9C7A1C,
  0xFF7C3AED,
  0xFF0D9488,
  0xFFDB2777,
  0xFF64748B,
];

/// نمودار دوناتیِ سهم دسته‌ها از هزینه.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, required this.palette});

  final List<CategorySlice> slices;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final int total =
        slices.fold<int>(0, (sum, item) => sum + item.amount.minorUnits);
    if (total <= 0) {
      return Text(
        'هزینه‌ای در این ماه ثبت نشده است.',
        style: TextStyle(color: palette.textSecondary, fontSize: 13),
      );
    }
    final List<double> fractions = <double>[
      for (final CategorySlice slice in slices)
        slice.amount.minorUnits / total,
    ];
    return Container(
      height: 150,
      alignment: AlignmentDirectional.center,
      child: CustomPaint(
        painter: _DonutPainter(
          fractions: fractions,
          colors: <Color>[
            for (int index = 0; index < slices.length; index++)
              Color(_chartColors[index % _chartColors.length]),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${toPersianDigits(slices.length)} دسته',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                formatMinorUnits(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.fractions, required this.colors});

  final List<double> fractions;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.butt;
    final Rect arcRect = rect.deflate(30);
    double start = -1.5707963267948966; // بالا (ساعت ۱۲)
    for (int index = 0; index < fractions.length; index++) {
      final double sweep = fractions[index] * 6.283185307179586;
      paint.color = colors[index];
      canvas.drawArc(arcRect, start, sweep - 0.035, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.fractions != fractions || oldDelegate.colors != colors;
}

/// نمودار خطیِ روند درآمد و هزینه در ۶ بازهٔ شمسی.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.points, required this.palette});

  final List<TrendPoint> points;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return CustomPaint(
            painter: _TrendPainter(
              points: points,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              palette: palette,
            ),
          );
        },
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.points,
    required this.width,
    required this.height,
    required this.palette,
  });

  final List<TrendPoint> points;
  final double width;
  final double height;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final int maxMinorUnits = points.fold<int>(
      0,
      (max, point) => point.income.minorUnits > max
          ? point.income.minorUnits
          : point.expense.minorUnits > max
              ? point.expense.minorUnits
              : max,
    );
    if (maxMinorUnits <= 0) {
      return;
    }
    final Paint gridPaint = Paint()
      ..color = palette.divider.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (int gridLine = 1; gridLine < 4; gridLine++) {
      final double y = height * gridLine / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    void drawSeries(
      double Function(TrendPoint) valueOf,
      Color color,
      double lineWidth,
      bool fill,
    ) {
      if (points.every((TrendPoint point) => valueOf(point) <= 0)) {
        return;
      }
      final Path path = Path();
      for (int index = 0; index < points.length; index++) {
        final double x = points.length == 1
            ? width / 2
            : width * index / (points.length - 1);
        final double y = height -
            (height * 0.86 *
                (valueOf(points[index]) / maxMinorUnits).clamp(0.0, 1.0));
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      if (fill) {
        final Path fillPath = Path.from(path)
          ..lineTo(width, height)
          ..lineTo(0, height)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = color.withValues(alpha: 0.09)
            ..style = PaintingStyle.fill,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = lineWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      final Paint dotPaint = Paint()..color = color;
      for (int index = 0; index < points.length; index++) {
        final double x = points.length == 1
            ? width / 2
            : width * index / (points.length - 1);
        final double y = height -
            (height * 0.86 *
                (valueOf(points[index]) / maxMinorUnits).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }

    drawSeries((TrendPoint point) => point.expense.minorUnits.toDouble(),
        palette.danger, 2.4, true);
    drawSeries((TrendPoint point) => point.income.minorUnits.toDouble(),
        palette.positive, 2.4, false);

    final TextPainter labelPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );
    const TextStyle labelStyle = TextStyle(fontSize: 10);
    for (int index = 0; index < points.length; index++) {
      final double x = points.length == 1
          ? width / 2
          : width * index / (points.length - 1);
      labelPainter.text = TextSpan(
        text: points[index].label,
        style: labelStyle.copyWith(color: palette.textMuted),
      );
      labelPainter.layout();
      final double clampedX = (x - labelPainter.width / 2)
          .clamp(0.0, (width - labelPainter.width).clamp(0.0, double.infinity));
      labelPainter.paint(
        canvas,
        Offset(clampedX, height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.width != width ||
      oldDelegate.height != height;
}

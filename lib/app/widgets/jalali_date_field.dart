import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_dimensions.dart';

/// فیلد تاریخ شمسی سه‌تکه (روز/ماه/سال) با احترام به تعداد روزهای هر ماه و
/// سال کبیسه؛ تغییر ماه/سال روز را در صورت نیاز به سقف ماه اصلاح می‌کند.
class JalaliDateField extends StatefulWidget {
  const JalaliDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'تاریخ',
  });

  final JalaliDate value;
  final ValueChanged<JalaliDate> onChanged;
  final String label;

  @override
  State<JalaliDateField> createState() => _JalaliDateFieldState();
}

class _JalaliDateFieldState extends State<JalaliDateField> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.value.year;
    _month = widget.value.month;
    _day = widget.value.day;
  }

  void _emit() {
    final int maxDay = JalaliDate.daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
    widget.onChanged(JalaliDate(_year, _month, _day));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int todayYear = JalaliDate.today().year;
    final int minYear = todayYear - 20;
    final int maxYear = todayYear + 30;
    final int maxDay = JalaliDate.daysInMonth(_year, _month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('jalali-day'),
                initialValue: _day,
                decoration: const InputDecoration(
                  labelText: 'روز',
                  counterText: '',
                ),
                items: <DropdownMenuItem<int>>[
                  for (int day = 1; day <= maxDay; day++)
                    DropdownMenuItem<int>(
                      value: day,
                      child: Text(toPersianDigits(day)),
                    ),
                ],
                onChanged: (int? day) {
                  if (day != null) {
                    _day = day;
                    _emit();
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('jalali-month'),
                initialValue: _month,
                decoration: const InputDecoration(
                  labelText: 'ماه',
                  counterText: '',
                ),
                items: <DropdownMenuItem<int>>[
                  for (int month = 1; month <= 12; month++)
                    DropdownMenuItem<int>(
                      value: month,
                      child: Text(JalaliDate.monthNames[month - 1]),
                    ),
                ],
                onChanged: (int? month) {
                  if (month != null) {
                    _month = month;
                    _emit();
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('jalali-year'),
                initialValue: _year,
                decoration: const InputDecoration(
                  labelText: 'سال',
                  counterText: '',
                ),
                items: <DropdownMenuItem<int>>[
                  for (int year = minYear; year <= maxYear; year++)
                    DropdownMenuItem<int>(
                      value: year,
                      child: Text(toPersianDigits(year)),
                    ),
                ],
                onChanged: (int? year) {
                  if (year != null) {
                    _year = year;
                    _emit();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

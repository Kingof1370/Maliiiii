import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/calendar_data.dart';
import '../state/ledger_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_card.dart';

/// تقویم شمسی با رویدادهای روزانه (درآمد/هزینه/انتقال/قسط).
///
/// طراحی با زبان سه‌بعدی هماهنگ است: کارت ماه عمق‌دار، سلول‌های روز با
/// نشانگر رویداد، وضعیت مالی روز و انیمیشن انتخاب روز؛ عملکرد تقویم فدای
/// ظاهر نمی‌شود (سلول‌ها سبک و بدون رندر سنگین).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late JalaliDate _current;
  late JalaliDate _selected;
  final JalaliDate _today = JalaliDate.fromDateTime(DateTime.now());

  @override
  void initState() {
    super.initState();
    _current = JalaliDate(_today.year, _today.month, 1);
    _selected = _today;
  }

  void _goPrev() => setState(() => _current = _current.addMonths(-1));

  void _goNext() => setState(() => _current = _current.addMonths(1));

  void _goToday() {
    setState(() {
      _current = JalaliDate(_today.year, _today.month, 1);
      _selected = _today;
    });
  }

  static String _key(JalaliDate date) =>
      '${date.year}-${date.month}-${date.day}';

  @override
  Widget build(BuildContext context) {
    final FinancialLedger ledger = LedgerScope.of(context).ledger;
    final AppPalette palette = context.appPalette;
    final int days = JalaliDate.daysInMonth(_current.year, _current.month);
    final int offset =
        JalaliDate(_current.year, _current.month, 1).weekdayIndex;
    final List<JalaliDate?> cells = List<JalaliDate?>.filled(42, null);
    for (int index = 0; index < days; index++) {
      cells[offset + index] = JalaliDate(_current.year, _current.month, index + 1);
    }
    final Map<String, List<DayEvent>> monthEvents = <String, List<DayEvent>>{};
    for (final JalaliDate? day in cells) {
      if (day == null) continue;
      monthEvents[_key(day)] = eventsForDay(day, ledger);
    }
    final List<DayEvent> selectedEvents = eventsForDay(_selected, ledger);
    final int status = dayStatus(selectedEvents);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          _buildHeader(palette),
          const SizedBox(height: AppDimensions.spaceMd),
          _buildMonthCard(palette, cells, monthEvents),
          const SizedBox(height: AppDimensions.spaceMd),
          _buildDayDetails(palette, selectedEvents, status),
          const SizedBox(height: AppDimensions.spaceLg),
        ],
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Row(
      children: <Widget>[
        Text(
          'تقویم شمسی',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        IconButton(
          key: const Key('cal-prev-month'),
          tooltip: 'ماه قبل',
          onPressed: _goPrev,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Text(
          '${toPersianDigits(_current.year)} ${_current.monthName}',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        IconButton(
          key: const Key('cal-next-month'),
          tooltip: 'ماه بعد',
          onPressed: _goNext,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }

  Widget _buildMonthCard(
    AppPalette palette,
    List<JalaliDate?> cells,
    Map<String, List<DayEvent>> monthEvents,
  ) {
    return PremiumCard(
      elevation: PremiumElevation.raised,
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final String name in JalaliDate.weekdayNames)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (int row = 0; row < 6; row++)
            Row(
              children: <Widget>[
                for (int column = 0; column < 7; column++)
                  _buildDayCell(
                    palette,
                    cells[row * 7 + column],
                    monthEvents,
                  ),
              ],
            ),
          if (!_selected.isSameDay(_today))
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spaceXs),
              child: TextButton.icon(
                key: const Key('cal-go-today'),
                onPressed: _goToday,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('بازگشت به امروز'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    AppPalette palette,
    JalaliDate? day,
    Map<String, List<DayEvent>> monthEvents,
  ) {
    if (day == null) return const Expanded(child: SizedBox.shrink());

    final List<DayEvent> events = monthEvents[_key(day)] ?? const <DayEvent>[];
    final bool selected = day.isSameDay(_selected);
    final bool isToday = day.isSameDay(_today);
    final bool motion = AppDimensions.motionEnabled(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: GestureDetector(
          onTap: () => setState(() => _selected = day),
          child: AnimatedContainer(
            duration: motion ? AppDimensions.motionMedium : Duration.zero,
            curve: Curves.easeOutCubic,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? palette.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(color: palette.gold, width: 1.4)
                  : null,
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  toPersianDigits(day.day),
                  style: TextStyle(
                    color: selected
                        ? palette.primary
                        : (isToday ? palette.gold : palette.textSecondary),
                    fontWeight: selected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                _EventDots(events: events, palette: palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetails(
    AppPalette palette,
    List<DayEvent> events,
    int status,
  ) {
    final String dateLabel = '${_selected.weekdayName} '
        '${toPersianDigits(_selected.day)} ${_selected.monthName} '
        '${toPersianDigits(_selected.year)}';

    return PremiumCard(
      elevation: PremiumElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_statusIcon(status), size: 18, color: _statusColor(status, palette)),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(
                dateLabel,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceMd,
              ),
              child: Center(
                child: Text(
                  'در این روز رویدادی نیست',
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            for (final DayEvent event in events) _EventRow(event: event),
        ],
      ),
    );
  }

  IconData _statusIcon(int status) => switch (status) {
        1 => Icons.trending_up_rounded,
        -1 => Icons.trending_down_rounded,
        _ => Icons.remove_rounded,
      };

  Color _statusColor(int status, AppPalette palette) => switch (status) {
        1 => palette.positive,
        -1 => palette.danger,
        _ => palette.textMuted,
      };
}

class _EventDots extends StatelessWidget {
  const _EventDots({required this.events, required this.palette});

  final List<DayEvent> events;
  final AppPalette palette;

  Color _color(CalendarEventKind kind) => switch (kind) {
        CalendarEventKind.income => palette.positive,
        CalendarEventKind.expense => palette.danger,
        CalendarEventKind.transfer => palette.info,
        CalendarEventKind.installmentPayment ||
        CalendarEventKind.installmentDue => palette.gold,
      };

  @override
  Widget build(BuildContext context) {
    final Iterable<CalendarEventKind> kinds = <CalendarEventKind>{
      for (final DayEvent event in events) event.kind,
    }.take(3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final CalendarEventKind kind in kinds)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _color(kind),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final DayEvent event;

  IconData _icon(CalendarEventKind kind) => switch (kind) {
        CalendarEventKind.income => Icons.add_rounded,
        CalendarEventKind.expense => Icons.remove_rounded,
        CalendarEventKind.transfer => Icons.swap_horiz_rounded,
        CalendarEventKind.installmentPayment => Icons.payments_rounded,
        CalendarEventKind.installmentDue => Icons.alarm_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    final bool income = event.kind == CalendarEventKind.income;
    final bool expense = event.kind == CalendarEventKind.expense;
    final Color color = switch (event.kind) {
      CalendarEventKind.income => palette.positive,
      CalendarEventKind.expense => palette.danger,
      CalendarEventKind.transfer => palette.info,
      CalendarEventKind.installmentPayment ||
      CalendarEventKind.installmentDue => palette.gold,
    };
    final String sign = income ? '+' : (expense ? '−' : '');
    final String amount =
        '$sign${formatMinorUnits(event.amount.minorUnits, suffix: '')} تومان';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(event.kind), size: 16, color: color),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              event.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: income ? palette.positive : palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state.dart';
import '../../../theme/app_theme.dart';

enum CalendarMode { week, month }

class HorizontalWeekCalendarDialog extends StatefulWidget {
  final CalendarMode initialMode;
  final Function(DateTime)? onDatePicked;

  const HorizontalWeekCalendarDialog({
    super.key,
    this.initialMode = CalendarMode.week,
    this.onDatePicked,
  });

  @override
  State<HorizontalWeekCalendarDialog> createState() =>
      _HorizontalWeekCalendarDialogState();
}

class _HorizontalWeekCalendarDialogState
    extends State<HorizontalWeekCalendarDialog> {
  late CalendarMode _mode;
  late DateTime _weekStart;
  late DateTime _selectedDate;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final appState = Provider.of<AppState>(context, listen: false);
    _weekStart = AppState.getMondayOfWeek(appState.selectedWeekStart);
    _selectedDate = _weekStart;
    _displayMonth = DateTime(_weekStart.year, _weekStart.month, 1);
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }

  String _weekdayFull(int weekday) {
    switch (weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return 'Понедельник';
    }
  }

  String _monthFull(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return months[month - 1];
  }

  String _monthShort(int month) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthShort(date.month)}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _selectAndApply(DateTime date, AppState appState) {
    setState(() {
      _selectedDate = date;
    });

    if (widget.onDatePicked != null) {
      widget.onDatePicked!(date);
    } else {
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      final monday = AppState.getMondayOfWeek(date);
      appState.selectWeek(monday);
      appState.selectDay(
        _weekdayFull(date.weekday),
        dateStr: dateStr,
      );
    }
    Navigator.pop(context);
  }

  bool _hasLessonsOnDate(DateTime date, AppState appState) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final day =
        appState.schedule?.days.where((d) => d.date == dateStr).firstOrNull;
    return day != null && day.lessons.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segmented mode switcher: [ Мини-календарь | Полный календарь ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _mode = CalendarMode.week),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _mode == CalendarMode.week
                              ? AppTheme.dockActiveAmber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.view_week_rounded,
                              size: 16,
                              color: _mode == CalendarMode.week
                                  ? Colors.black
                                  : subtext,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Мини (Неделя)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: _mode == CalendarMode.week
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _mode == CalendarMode.week
                                    ? Colors.black
                                    : subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _mode = CalendarMode.month),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _mode == CalendarMode.month
                              ? AppTheme.dockActiveAmber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: _mode == CalendarMode.month
                                  ? Colors.black
                                  : subtext,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Полный (Месяц)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: _mode == CalendarMode.month
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _mode == CalendarMode.month
                                    ? Colors.black
                                    : subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Content according to mode
            if (_mode == CalendarMode.week)
              _buildMiniWeekView(appState, text, subtext, surface, divider)
            else
              _buildFullMonthView(appState, text, subtext, surface, divider),

            const SizedBox(height: 16),

            // Jump to Today button
            TextButton.icon(
              onPressed: () {
                final now = DateTime.now();
                _selectAndApply(now, appState);
              },
              icon: const Icon(Icons.today, size: 18),
              label: const Text('Перейти к сегодняшнему дню'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.dockActiveAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniWeekView(
    AppState appState,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final days = List<DateTime>.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );
    final now = DateTime.now();

    return Column(
      children: [
        // Week switcher header
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _weekStart = _weekStart.subtract(const Duration(days: 7));
                  _selectedDate = _weekStart;
                });
              },
              icon: Icon(Icons.chevron_left_rounded, color: text),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${_formatDate(_weekStart)} — ${_formatDate(weekEnd)}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_weekStart.year} год',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: subtext,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _weekStart = _weekStart.add(const Duration(days: 7));
                  _selectedDate = _weekStart;
                });
              },
              icon: Icon(Icons.chevron_right_rounded, color: text),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7 Days Grid/Row
        Row(
          children: days.map((date) {
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, now);
            final hasLessons = _hasLessonsOnDate(date, appState);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectAndApply(date, appState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.dockActiveAmber
                          : (isToday
                              ? AppTheme.dockActiveAmber.withValues(alpha: 0.12)
                              : surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.dockActiveAmber
                            : (isToday
                                ? AppTheme.dockActiveAmber.withValues(alpha: 0.5)
                                : divider),
                        width: isSelected || isToday ? 1.5 : 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdayShort(date.weekday),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.black
                                : (date.weekday >= 6 ? Colors.orange : subtext),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.black : text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasLessons
                                ? (isSelected ? Colors.black : AppTheme.dockActiveAmber)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFullMonthView(
    AppState appState,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    final now = DateTime.now();
    final year = _displayMonth.year;
    final month = _displayMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Find the Monday of the first calendar row
    final startMonday = AppState.getMondayOfWeek(firstDayOfMonth);

    // Generate weeks of dates (up to 6 weeks = 42 days)
    final calendarDates = List.generate(
      42,
      (i) => startMonday.add(Duration(days: i)),
    ).where((d) {
      if (d.isAfter(lastDayOfMonth) && d.weekday == DateTime.monday) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Month switcher header
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _displayMonth = DateTime(year, month - 1, 1);
                });
              },
              icon: Icon(Icons.chevron_left_rounded, color: text),
            ),
            Expanded(
              child: Text(
                '${_monthFull(month)} $year',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _displayMonth = DateTime(year, month + 1, 1);
                });
              },
              icon: Icon(Icons.chevron_right_rounded, color: text),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Weekday headers
        Row(
          children: List.generate(7, (i) {
            final w = i + 1;
            return Expanded(
              child: Text(
                _weekdayShort(w),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: w >= 6 ? Colors.orange : subtext,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Month Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemCount: calendarDates.length,
          itemBuilder: (context, index) {
            final date = calendarDates[index];
            final isCurrentMonth = date.month == month;
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, now);
            final hasLessons = _hasLessonsOnDate(date, appState);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectAndApply(date, appState),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.dockActiveAmber
                      : (isToday
                          ? AppTheme.dockActiveAmber.withValues(alpha: 0.15)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: AppTheme.dockActiveAmber.withValues(alpha: 0.6))
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.black
                            : (isCurrentMonth
                                ? text
                                : subtext.withValues(alpha: 0.35)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLessons
                            ? (isSelected
                                ? Colors.black
                                : AppTheme.dockActiveAmber)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

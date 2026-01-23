import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state.dart';

class HorizontalWeekCalendarDialog extends StatefulWidget {
  @override
  _HorizontalWeekCalendarDialogState createState() => _HorizontalWeekCalendarDialogState();
}

class _HorizontalWeekCalendarDialogState extends State<HorizontalWeekCalendarDialog> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _weekStart = _normalizeToMonday(appState.selectedWeekStart);
    _selectedDate = _weekStart;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final days = List<DateTime>.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.subtract(const Duration(days: 7));
                      _selectedDate = _weekStart;
                    });
                    appState.selectWeek(_weekStart);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_formatDate(weekStart: _weekStart)} — ${_formatDate(weekStart: weekEnd)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Неделя',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
                    appState.selectWeek(_weekStart);
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: days.map((date) {
                final isSelected = _isSameDay(date, _selectedDate);
                final bg = isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor;
                final fg = isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          _weekStart = _normalizeToMonday(date);
                        });
                        // При выборе дня сразу переключаем расписание на этот день
                        appState.selectWeek(_weekStart);
                        appState.selectDay(_weekdayFull(date.weekday));
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 74,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayShort(date.weekday),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fg?.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _monthShort(date.month),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fg?.withOpacity(0.85),
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
        ),
      ),
    );
  }

  DateTime _normalizeToMonday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'ПН';
      case DateTime.tuesday:
        return 'ВТ';
      case DateTime.wednesday:
        return 'СР';
      case DateTime.thursday:
        return 'ЧТ';
      case DateTime.friday:
        return 'ПТ';
      case DateTime.saturday:
        return 'СБ';
      case DateTime.sunday:
        return 'ВС';
      default:
        return '';
    }
  }

  String _weekdayFull(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Понедельник';
      case DateTime.tuesday:
        return 'Вторник';
      case DateTime.wednesday:
        return 'Среда';
      case DateTime.thursday:
        return 'Четверг';
      case DateTime.friday:
        return 'Пятница';
      case DateTime.saturday:
        return 'Суббота';
      case DateTime.sunday:
        return 'Воскресенье';
      default:
        return 'Понедельник';
    }
  }

  String _monthShort(int month) {
    switch (month) {
      case 1:
        return 'янв';
      case 2:
        return 'фев';
      case 3:
        return 'мар';
      case 4:
        return 'апр';
      case 5:
        return 'май';
      case 6:
        return 'июн';
      case 7:
        return 'июл';
      case 8:
        return 'авг';
      case 9:
        return 'сен';
      case 10:
        return 'окт';
      case 11:
        return 'ноя';
      case 12:
        return 'дек';
      default:
        return '';
    }
  }

  String _formatDate({required DateTime weekStart}) {
    final dd = weekStart.day.toString().padLeft(2, '0');
    final mm = weekStart.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }
}

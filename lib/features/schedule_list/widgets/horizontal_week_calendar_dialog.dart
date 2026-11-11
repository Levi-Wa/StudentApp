import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state.dart';
import '../../../theme/app_theme.dart';

class HorizontalWeekCalendarDialog extends StatefulWidget {
  const HorizontalWeekCalendarDialog({super.key});

  @override
  State<HorizontalWeekCalendarDialog> createState() =>
      _HorizontalWeekCalendarDialogState();
}

class _HorizontalWeekCalendarDialogState
    extends State<HorizontalWeekCalendarDialog> {
  late DateTime _weekStart;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _weekStart = AppState.getMondayOfWeek(appState.selectedWeekStart);
    _selectedDate = _weekStart;
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

  String _monthShort(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthShort(date.month)}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final days = List<DateTime>.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  icon: Icon(Icons.chevron_left, color: AppTheme.primaryText),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_formatDate(_weekStart)} — ${_formatDate(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_weekStart.year} год',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
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
                  icon: Icon(Icons.chevron_right, color: AppTheme.primaryText),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7 Days Grid/Row
            Row(
              children: days.map((date) {
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, now);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                        final dateStr =
                            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                        appState.selectWeek(_weekStart);
                        appState.selectDay(
                          _weekdayFull(date.weekday),
                          dateStr: dateStr,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryAccent
                              : (isToday
                                  ? AppTheme.primaryAccent.withOpacity(0.12)
                                  : AppTheme.surfaceBackground),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryAccent
                                : (isToday
                                    ? AppTheme.primaryAccent.withOpacity(0.5)
                                    : AppTheme.dividerColor),
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
                                    ? Colors.white
                                    : (date.weekday >= 6
                                        ? Colors.orange
                                        : AppTheme.secondaryText),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primaryText,
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
            const SizedBox(height: 16),

            // Jump to Today button
            TextButton.icon(
              onPressed: () {
                appState.goToToday();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.today, size: 18),
              label: const Text('Перейти к текущей неделе'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

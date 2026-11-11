import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/day_schedule.dart';
import '../../data/providers/app_state.dart';
import '../../data/providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';
import 'widgets/lesson_card.dart';
import 'widgets/horizontal_week_calendar_dialog.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'ПН';
      case 2:
        return 'ВТ';
      case 3:
        return 'СР';
      case 4:
        return 'ЧТ';
      case 5:
        return 'ПТ';
      case 6:
        return 'СБ';
      case 7:
        return 'ВС';
      default:
        return '';
    }
  }

  String _getDayName(int weekday) {
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

  String _getMonthShort(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month - 1];
  }

  Future<void> _handleRefresh() async {
    _refreshAnimController.repeat();
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.forceUpdateSchedule();
    _refreshAnimController.stop();
    _refreshAnimController.reset();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Расписание успешно обновлено с сервера'
                : 'Не удалось обновить: проверьте соединение',
          ),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final notesProvider = Provider.of<NotesProvider>(context);

    final now = DateTime.now();
    final weekStart = appState.selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isCurrentWeek =
        AppState.getMondayOfWeek(now) == AppState.getMondayOfWeek(weekStart);

    // 7 дней недели от понедельника до воскресенья
    final weekDateList =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final weekDays = appState.currentWeekDays;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context, appState, notesProvider.notes.length),

            // Week Switcher bar (<, Week Range, Today, >)
            _buildWeekBar(context, appState, weekStart, weekEnd, isCurrentWeek),

            // Horizontal Day Selector Strip
            _buildDayStrip(appState, weekDateList, weekDays, now),

            // Main Schedule Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppTheme.primaryAccent,
                child: _buildBody(appState, weekDays),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, AppState appState, int notesCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Group badge
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryAccent.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: AppTheme.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appState.currentGroupName ?? 'Группа не выбрана',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.primaryAccent,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Refresh button with animation
          IconButton(
            tooltip: 'Обновить расписание',
            icon: RotationTransition(
              turns: _refreshAnimController,
              child: Icon(
                Icons.refresh_rounded,
                color: appState.isRefreshing
                    ? AppTheme.primaryAccent
                    : AppTheme.primaryText,
              ),
            ),
            onPressed: appState.isRefreshing ? null : _handleRefresh,
          ),

          // Notes button with badge
          Stack(
            children: [
              IconButton(
                tooltip: 'Заметки',
                icon: Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.primaryText,
                  size: 26,
                ),
                onPressed: () => Navigator.pushNamed(context, '/notes'),
              ),
              if (notesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notesCount > 99 ? '99+' : '$notesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Settings button
          IconButton(
            tooltip: 'Настройки',
            icon: Icon(
              Icons.settings_outlined,
              color: AppTheme.primaryText,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBar(BuildContext context, AppState appState,
      DateTime weekStart, DateTime weekEnd, bool isCurrentWeek) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.secondaryBackground,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Предыдущая неделя',
            color: AppTheme.primaryText,
            onPressed: () => appState.previousWeek(),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const HorizontalWeekCalendarDialog(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 15,
                      color: AppTheme.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${weekStart.day} ${_getMonthShort(weekStart.month)} — ${weekEnd.day} ${_getMonthShort(weekEnd.month)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isCurrentWeek)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 30),
              ),
              onPressed: () => appState.goToToday(),
              child: Text(
                'Сегодня',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Следующая неделя',
            color: AppTheme.primaryText,
            onPressed: () => appState.nextWeek(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip(AppState appState, List<DateTime> weekDateList,
      List<DaySchedule> weekDays, DateTime now) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 0.8),
        ),
      ),
      child: Row(
        children: weekDateList.map((date) {
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final dateStr =
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
          final dayName = _getDayName(date.weekday);

          // Проверяем, выбран ли этот день
          final isSelected = appState.selectedDateStr == dateStr ||
              (appState.selectedDateStr == null &&
                  appState.selectedDay == dayName);

          // Проверяем, есть ли занятия в этот день
          final daySchedule =
              weekDays.where((d) => d.date == dateStr).firstOrNull;
          final hasLessons =
              daySchedule != null && daySchedule.lessons.isNotEmpty;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  appState.selectDay(dayName, dateStr: dateStr);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryAccent
                        : (isToday
                            ? AppTheme.primaryAccent.withOpacity(0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryAccent
                          : (isToday
                              ? AppTheme.primaryAccent.withOpacity(0.4)
                              : Colors.transparent),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayAbbreviation(date.weekday),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : (date.weekday >= 6
                                  ? Colors.orange
                                  : AppTheme.secondaryText),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Dot indicator for lessons
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: hasLessons
                              ? (isSelected ? Colors.white : AppTheme.primaryAccent)
                              : Colors.transparent,
                          shape: BoxShape.circle,
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
    );
  }

  Widget _buildBody(AppState appState, List<DaySchedule> weekDays) {
    if (appState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryAccent),
            const SizedBox(height: 16),
            Text(
              'Загрузка расписания...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    if (appState.schedule == null || appState.schedule!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: AppTheme.secondaryText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Расписание не найдено',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте потянуть вниз для обновления или выберите другую группу в настройках',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ищем выбранный день
    DaySchedule? selectedDay;
    if (appState.selectedDateStr != null) {
      selectedDay =
          weekDays.where((d) => d.date == appState.selectedDateStr).firstOrNull;
    }
    selectedDay ??=
        weekDays.where((d) => d.dayOfWeek == appState.selectedDay).firstOrNull;

    if (selectedDay == null || selectedDay.lessons.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.weekend_rounded,
                    size: 56,
                    color: AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'В этот день пар нет!',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveText.title(context),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Отличный повод отдохнуть или заняться своими делами',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveText.body(context),
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      itemCount: selectedDay.lessons.length,
      itemBuilder: (context, index) {
        return LessonCard(
          lesson: selectedDay!.lessons[index],
          lessonDate: selectedDay.date,
        );
      },
    );
  }
}

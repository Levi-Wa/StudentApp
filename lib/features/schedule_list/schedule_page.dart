import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/day_schedule.dart';
import '../../data/providers/app_state.dart';
import '../../data/providers/notes_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/services/update_service.dart';
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
  bool _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Silent check for updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStartupUpdate();
    });
  }

  void _checkStartupUpdate() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;
    try {
      final info = await UpdateService().checkForUpdate();
      if (mounted && info != null && info.hasUpdate) {
        UpdateService.showUpdateModal(context, info);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  String _getDaySingleLetter(int weekday) {
    switch (weekday) {
      case 1:
        return 'П';
      case 2:
        return 'В';
      case 3:
        return 'С';
      case 4:
        return 'Ч';
      case 5:
        return 'П';
      case 6:
        return 'С';
      case 7:
        return 'В';
      default:
        return '';
    }
  }

  String _getDayShort(int weekday) {
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

  String _getDayFullName(int weekday) {
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
                : 'Не удалось обновить: проверьте интернет-соединение',
          ),
          backgroundColor:
              success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild immediately when theme changes
    context.watch<ThemeProvider>();
    final appState = Provider.of<AppState>(context);
    final notesProvider = Provider.of<NotesProvider>(context);

    final bg = AppTheme.bg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final divider = AppTheme.divider(context);

    final now = DateTime.now();
    final weekStart = appState.selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isCurrentWeek =
        AppState.getMondayOfWeek(now) == AppState.getMondayOfWeek(weekStart);

    final weekDateList =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekDays = appState.currentWeekDays;

    // Determine current selected day date
    DateTime activeDate = now;
    if (appState.selectedDateStr != null) {
      final parts = appState.selectedDateStr!.split('.');
      if (parts.length == 3) {
        activeDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Row(
          children: [
            // ==================== LEFT VERTICAL RAIL (DOCK) ====================
            _buildLeftDock(
              context,
              appState,
              weekDateList,
              weekDays,
              now,
              notesProvider.notes.length,
            ),

            // ==================== MAIN CONTENT AREA ====================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Date Badge & Title
                  _buildHeader(
                    context,
                    appState,
                    activeDate,
                    weekStart,
                    weekEnd,
                    isCurrentWeek,
                    text,
                    subtext,
                    divider,
                  ),

                  // Lesson list with RefreshIndicator
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppTheme.dockActiveAmber,
                      child: _buildLessonTimeline(appState, weekDays, text, subtext),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left vertical dock matching the design in Image 1
  Widget _buildLeftDock(
    BuildContext context,
    AppState appState,
    List<DateTime> weekDateList,
    List<DaySchedule> weekDays,
    DateTime now,
    int notesCount,
  ) {
    return Container(
      width: 62,
      margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
      decoration: BoxDecoration(
        color: AppTheme.dockBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // Top Icon: 4-square App / Menu button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const HorizontalWeekCalendarDialog(),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const Spacer(),

          // Center: The 7 days of the week (M, T, W, T, F, S, S)
          ...List.generate(7, (index) {
            final date = weekDateList[index];
            final dateStr =
                '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
            final dayName = _getDayFullName(date.weekday);

            final isSelected = appState.selectedDateStr == dateStr ||
                (appState.selectedDateStr == null &&
                    appState.selectedDay == dayName);

            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            final daySchedule =
                weekDays.where((d) => d.date == dateStr).firstOrNull;
            final hasLessons =
                daySchedule != null && daySchedule.lessons.isNotEmpty;

            final letter = _getDaySingleLetter(date.weekday);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () {
                  appState.selectDay(dayName, dateStr: dateStr);
                },
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Day pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.dockActiveAmber
                            : (isToday
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppTheme.dockActiveAmber
                                    .withValues(alpha: 0.5),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.black
                                : (hasLessons
                                    ? Colors.white
                                    : AppTheme.dockItemInactive),
                          ),
                        ),
                      ),
                    ),

                    // Active pointer / tab notch pointing to schedule (Image 1)
                    if (isSelected)
                      Positioned(
                        right: -10,
                        child: Container(
                          width: 5,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppTheme.dockActiveAmber,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),

                    // Dot indicator for lessons
                    if (hasLessons && !isSelected)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.dockActiveAmber
                                : Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // Notes button with badge
          Stack(
            children: [
              IconButton(
                tooltip: 'Заметки',
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Navigator.pushNamed(context, '/notes'),
              ),
              if (notesCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.dockActiveAmber,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notesCount > 9 ? '9+' : '$notesCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Bottom Icon: Settings Gear (Image 1)
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.dockItemInactive,
              size: 22,
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Header matching Image 1: top date badge on right, bold Title on left
  Widget _buildHeader(
    BuildContext context,
    AppState appState,
    DateTime activeDate,
    DateTime weekStart,
    DateTime weekEnd,
    bool isCurrentWeek,
    Color text,
    Color subtext,
    Color divider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Group chip, Refresh button, Date Badge (Tues Aug 20 18 in Image 1)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Group Pill
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 15,
                        color: AppTheme.dockActiveAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        appState.currentGroupName ?? 'Выбрать группу',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: subtext,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Refresh Button
              IconButton(
                tooltip: 'Обновить расписание',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: RotationTransition(
                  turns: _refreshAnimController,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: appState.isRefreshing
                        ? AppTheme.dockActiveAmber
                        : subtext,
                    size: 20,
                  ),
                ),
                onPressed: appState.isRefreshing ? null : _handleRefresh,
              ),

              const Spacer(),

              // Right Date Badge: Day + Month + Big Date Number (Image 1 style)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getDayShort(activeDate.weekday),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subtext,
                        ),
                      ),
                      Text(
                        _getMonthShort(activeDate.month),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtext,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${activeDate.day}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: text,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title: "Расписание" (Image 1 Schedule)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Расписание',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: text,
                  letterSpacing: -0.5,
                ),
              ),

              // Week Selector strip
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const HorizontalWeekCalendarDialog(),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => appState.previousWeek(),
                        child: Icon(Icons.chevron_left_rounded,
                            size: 18, color: subtext),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${weekStart.day} ${_getMonthShort(weekStart.month)} — ${weekEnd.day} ${_getMonthShort(weekEnd.month)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => appState.nextWeek(),
                        child: Icon(Icons.chevron_right_rounded,
                            size: 18, color: subtext),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (!isCurrentWeek) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => appState.goToToday(),
                child: Text(
                  'Вернуться на текущую неделю',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dockActiveAmber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Timeline view showing lessons for the active day
  Widget _buildLessonTimeline(
    AppState appState,
    List<DaySchedule> weekDays,
    Color text,
    Color subtext,
  ) {
    if (appState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.dockActiveAmber),
            const SizedBox(height: 16),
            Text(
              'Загрузка расписания...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtext,
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
                size: 56,
                color: subtext.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Расписание не найдено',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Потяните вниз для обновления или выберите другую группу',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtext,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Обновить'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dockActiveAmber,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Locate the selected day
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
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.dockActiveAmber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.weekend_rounded,
                    size: 50,
                    color: AppTheme.dockActiveAmber,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'В этот день пар нет!',
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveText.title(context),
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Отличный повод отдохнуть или заняться своими проектами',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subtext,
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: selectedDay.lessons.length,
      itemBuilder: (context, index) {
        return LessonCard(
          lesson: selectedDay!.lessons[index],
          lessonDate: selectedDay.date,
          index: index,
        );
      },
    );
  }
}

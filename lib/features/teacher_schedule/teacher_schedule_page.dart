import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/teacher.dart';
import '../../data/services/teacher_service.dart';
import '../../theme/app_theme.dart';

class TeacherSchedulePage extends StatefulWidget {
  final Teacher teacher;
  final String? departmentName;

  const TeacherSchedulePage({
    super.key,
    required this.teacher,
    this.departmentName,
  });

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  String? _error;
  List<TeacherDaySchedule> _scheduleDays = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final days = await _teacherService.getTeacherSchedule(
        departId: widget.teacher.departId,
        empId: widget.teacher.empId,
      );
      if (mounted) {
        setState(() {
          _scheduleDays = days;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить расписание преподавателя: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String rawDate) {
    // rawDate is either YYYY-MM-DD or DD.MM.YYYY
    if (rawDate.contains('-')) {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    }
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bg(context);
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.teacher.fio,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            if (widget.departmentName != null)
              Text(
                widget.departmentName!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: subtext,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.dockActiveAmber),
            tooltip: 'Обновить',
            onPressed: _loadSchedule,
          ),
        ],
      ),
      body: _buildBody(bg, cardBg, text, subtext, surface, divider),
    );
  }

  Widget _buildBody(
    Color bg,
    Color cardBg,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.dockActiveAmber,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: text),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dockActiveAmber,
                  foregroundColor: Colors.black,
                ),
                onPressed: _loadSchedule,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scheduleDays.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, color: subtext, size: 56),
              const SizedBox(height: 12),
              Text(
                'Занятий для этого преподавателя не найдено',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'В текущем расписании у преподавателя нет назначенных пар на ближайший месяц.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtext,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _scheduleDays.length,
      itemBuilder: (context, index) {
        final day = _scheduleDays[index];
        return _buildDayCard(day, cardBg, text, subtext, surface, divider);
      },
    );
  }

  Widget _buildDayCard(
    TeacherDaySchedule day,
    Color cardBg,
    Color text,
    Color subtext,
    Color surface,
    Color divider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dockActiveAmber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day.dayOfWeekShort.isNotEmpty ? day.dayOfWeekShort : 'День',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  day.dayOfWeek,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(day.date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtext,
                  ),
                ),
              ],
            ),
          ),

          // Lessons list
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: day.lessons.asMap().entries.map((entry) {
                final lIndex = entry.key;
                final lesson = entry.value;
                final (cardColor, fgPrimary, fgSec, badgeBg) =
                    AppTheme.getLessonStyle(lesson.loadKind, lIndex);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lesson.time,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: fgPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (lesson.loadKind.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lesson.loadKind,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: fgPrimary,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Room
                          if (lesson.aud.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.room_rounded,
                                    size: 14, color: fgSec),
                                const SizedBox(width: 3),
                                Text(
                                  'Ауд. ${lesson.aud}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: fgPrimary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Subject name
                      Text(
                        lesson.subjName,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: fgPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Group Pill
                      Row(
                        children: [
                          Icon(Icons.groups_rounded, size: 14, color: fgSec),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Группа: ${lesson.groupName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: fgSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

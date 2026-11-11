import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/lesson.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final String? lessonDate;

  const LessonCard({super.key, required this.lesson, this.lessonDate});

  String _calculateEndTime(String startTime) {
    try {
      final parts = startTime.split(':');
      if (parts.length == 2) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]) + 90; // 90 минут на пару
        if (minutes >= 60) {
          hours += minutes ~/ 60;
          minutes = minutes % 60;
        }
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return '';
  }

  bool _isToday() {
    if (lessonDate == null) return false;
    final now = DateTime.now();
    try {
      final parts = lessonDate!.split('.');
      if (parts.length == 3) {
        final lessonDateTime = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return lessonDateTime.year == now.year &&
            lessonDateTime.month == now.month &&
            lessonDateTime.day == now.day;
      }
    } catch (_) {}
    return false;
  }

  bool _isNow(String startTime, String endTime) {
    if (!_isToday()) return false;
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      }
    } catch (_) {}
    return false;
  }

  bool _isPast(String endTime) {
    if (!_isToday()) return false;
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final endParts = endTime.split(':');
      if (endParts.length == 2) {
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        return currentMinutes > endMinutes;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final times = lesson.time.split('-');
    final startTime = times.isNotEmpty ? times[0].trim() : '';
    final endTime = times.length > 1 ? times[1].trim() : _calculateEndTime(startTime);

    final isCurrent = _isNow(startTime, endTime);
    final isFinished = _isPast(endTime);

    final (typeBg, typeFg) = AppTheme.getLessonTypeColors(lesson.vidZan);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF10B981) // Green border for live lesson
              : AppTheme.dividerColor,
          width: isCurrent ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? const Color(0xFF10B981).withOpacity(0.12)
                : Colors.black.withOpacity(0.03),
            blurRadius: isCurrent ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side: Type accent strip + Time
              Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF10B981).withOpacity(0.08)
                      : AppTheme.surfaceBackground,
                  border: Border(
                    right: BorderSide(
                      color: AppTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'СЕЙЧАС',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      startTime,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveText.body(context),
                        fontWeight: FontWeight.w700,
                        color: isFinished
                            ? AppTheme.secondaryText
                            : AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endTime,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveText.small(context),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: Lesson details
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge row: Type + Room
                      Row(
                        children: [
                          if (lesson.vidZan.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lesson.vidZan,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: typeFg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (lesson.aud.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.dividerColor,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 13,
                                    color: AppTheme.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lesson.aud,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Discipline Title
                      Text(
                        lesson.disc,
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.body(context),
                          fontWeight: FontWeight.w600,
                          color: isFinished
                              ? AppTheme.secondaryText
                              : AppTheme.primaryText,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Teacher row
                      if (lesson.prepod.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppTheme.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lesson.prepod,
                                style: GoogleFonts.inter(
                                  fontSize: ResponsiveText.small(context),
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

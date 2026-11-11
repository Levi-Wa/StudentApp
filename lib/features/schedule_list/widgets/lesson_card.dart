import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/lesson.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final String? lessonDate;
  final int index;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    this.lessonDate,
    this.index = 0,
    this.onTap,
  });

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
        final endMinutes =
            int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
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
        final endMinutes =
            int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        return currentMinutes > endMinutes;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final times = lesson.time.split('-');
    final startTime = times.isNotEmpty ? times[0].trim() : '';
    final endTime =
        times.length > 1 ? times[1].trim() : _calculateEndTime(startTime);

    final isCurrent = _isNow(startTime, endTime);
    final isFinished = _isPast(endTime);

    // Style from Image 1: vibrant solid cards (Cyan, Orange, Purple, Emerald, Amber)
    final (cardBg, textPrimary, textSecondary, badgeBg) =
        AppTheme.getLessonStyle(lesson.vidZan, index);

    final subtext = AppTheme.subtext(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column on the left (matching Image 1)
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (isCurrent) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'СЕЙЧАС',
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                Text(
                  startTime,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? const Color(0xFF10B981)
                        : (isFinished
                            ? subtext.withValues(alpha: 0.6)
                            : AppTheme.text(context)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endTime,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: subtext.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Vibrant rounded Lesson Card (matching Image 1)
          Expanded(
            child: InkWell(
              onTap: onTap ??
                  () => _showLessonDetails(context, startTime, endTime),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isFinished ? 0.75 : 1.0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cardBg.withValues(alpha: isCurrent ? 0.35 : 0.2),
                        blurRadius: isCurrent ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Title + Arrow / Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lesson.disc,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveText.body(context),
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: textPrimary.withValues(alpha: 0.75),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Lesson Type subtitle (e.g. Лекция / Практика)
                      if (lesson.vidZan.isNotEmpty) ...[
                        Text(
                          lesson.vidZan,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Bottom row: Room + Teacher
                      Row(
                        children: [
                          if (lesson.aud.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_rounded,
                                    size: 13,
                                    color: textPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    lesson.aud,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (lesson.prepod.isNotEmpty) ...[
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      lesson.prepod,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLessonDetails(
      BuildContext context, String startTime, String endTime) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1D24) : Colors.white;
        final text =
            isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subtext =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final surface =
            isDark ? const Color(0xFF222731) : const Color(0xFFEFF2F6);

        final (cardBg, _, _, _) =
            AppTheme.getLessonStyle(lesson.vidZan, index);

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtext.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color indicator + Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4, right: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lesson.disc,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.schedule_rounded,
                      'Время',
                      '$startTime — $endTime',
                      text,
                      subtext,
                    ),
                    if (lesson.vidZan.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.category_rounded,
                        'Тип занятия',
                        lesson.vidZan,
                        text,
                        subtext,
                      ),
                    ],
                    if (lesson.aud.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.meeting_room_rounded,
                        'Аудитория',
                        lesson.aud,
                        text,
                        subtext,
                      ),
                    ],
                    if (lesson.prepod.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.person_rounded,
                        'Преподаватель',
                        lesson.prepod,
                        text,
                        subtext,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: "Добавить заметку"
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dockActiveAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/notes');
                },
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(
                  'Добавить заметку к этому предмету',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color text,
    Color subtext,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: subtext),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: subtext,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ],
    );
  }
}

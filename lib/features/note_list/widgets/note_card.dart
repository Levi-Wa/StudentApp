import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../data/providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';
import 'edit_note_dialog.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExtend;

  const NoteCard({
    super.key,
    required this.note,
    this.index = 0,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExtend,
  });

  (Color bg, Color border) _getCardColor(bool isDark) {
    if (isDark) {
      switch (index % 5) {
        case 0:
          return (const Color(0xFF2E1C14), const Color(0xFF582A1B)); // Peach dark
        case 1:
          return (const Color(0xFF282512), const Color(0xFF4E461A)); // Sand dark
        case 2:
          return (const Color(0xFF2B210F), const Color(0xFF563D13)); // Amber dark
        case 3:
          return (const Color(0xFF221633), const Color(0xFF452769)); // Purple dark
        default:
          return (const Color(0xFF102336), const Color(0xFF1E3F61)); // Sky dark
      }
    } else {
      switch (index % 5) {
        case 0:
          return (const Color(0xFFFFEDD5), const Color(0xFFFED7AA)); // Peach light
        case 1:
          return (const Color(0xFFFEF3C7), const Color(0xFFFDE68A)); // Sand light
        case 2:
          return (const Color(0xFFFFF7ED), const Color(0xFFFED7AA)); // Amber light
        case 3:
          return (const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)); // Purple light
        default:
          return (const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)); // Sky light
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = note.isExpired;
    final (cardBg, cardBorder) = _getCardColor(isDark);

    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.dockActiveAmber.withValues(alpha: 0.15)
            : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppTheme.dockActiveAmber : cardBorder,
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onLongPress: onLongPress,
          onTap: onTap ?? () => _editNote(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection checkbox if in bulk mode
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    activeColor: AppTheme.dockActiveAmber,
                  ),
                  const SizedBox(width: 8),
                ],

                // Note info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject row + Expired badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.disc,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveText.body(context),
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExpired) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ПРОСРОЧЕНО',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Text content
                      Text(
                        note.text,
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.body(context),
                          color: textColor.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Due date badge (like Completion date in Image 1 Tasks)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isExpired
                                ? const Color(0xFFEF4444)
                                : subtextColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Срок: ${note.endDate.day.toString().padLeft(2, '0')}.${note.endDate.month.toString().padLeft(2, '0')}.${note.endDate.year} ${note.endLessonTime}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isExpired
                                    ? const Color(0xFFEF4444)
                                    : subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Interactive Checkbox / Actions (Image 1 style)
                if (!isSelectionMode) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Checkbox style button to mark done or delete
                      IconButton(
                        icon: const Icon(
                          Icons.check_box_outline_blank_rounded,
                          size: 22,
                        ),
                        tooltip: 'Отметить выполненным',
                        color: textColor.withValues(alpha: 0.7),
                        onPressed: () => _confirmDelete(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.update_rounded, size: 20),
                        tooltip: 'Перенести на след. пару',
                        color: AppTheme.dockActiveAmber,
                        onPressed: onExtend ?? () => _extendNote(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить задачу?'),
        content: Text('Удалить заметку по предмету «${note.disc}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dockActiveAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<NotesProvider>(context, listen: false)
                  .deleteNote(note.id);
            },
            child: const Text('Выполнено'),
          ),
        ],
      ),
    );
  }

  void _extendNote(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    if (appState.schedule != null) {
      notesProvider.extendToNextLesson(note, appState.schedule!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заметка перенесена на следующее занятие'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _editNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );
  }
}

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
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = note.isExpired;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryAccent.withOpacity(0.08)
            : AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryAccent
              : AppTheme.dividerColor,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: onLongPress,
          onTap: onTap ?? () => _editNote(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    activeColor: AppTheme.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  // Status indicator pill
                  Container(
                    width: 4,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isExpired
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // Note info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.disc,
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveText.body(context),
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryText,
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
                                color: const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ПРОСРОЧЕНО',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
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
                          color: AppTheme.primaryText.withOpacity(0.9),
                          height: 1.35,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Due date badge
                      Row(
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            size: 14,
                            color: isExpired
                                ? const Color(0xFFEF4444)
                                : AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'До ${note.endDate.day.toString().padLeft(2, '0')}.${note.endDate.month.toString().padLeft(2, '0')}.${note.endDate.year} ${note.endLessonTime}',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              fontWeight: FontWeight.w500,
                              color: isExpired
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons (when not in bulk selection mode)
                if (!isSelectionMode) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.update_rounded, size: 20),
                        tooltip: 'Перенести на след. пару',
                        color: AppTheme.primaryAccent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onExtend ?? () => _extendNote(context),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        tooltip: 'Редактировать',
                        color: AppTheme.secondaryText,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onEdit ?? () => _editNote(context),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 19),
                        tooltip: 'Удалить',
                        color: Colors.red.withOpacity(0.8),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete ?? () => _deleteNote(context),
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

  void _deleteNote(BuildContext context) {
    Provider.of<NotesProvider>(context, listen: false).deleteNote(note.id);
  }
}

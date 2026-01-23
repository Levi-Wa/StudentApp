import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../data/providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';
import 'edit_note_dialog.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onExtend;

  const NoteCard({
    Key? key,
    required this.note,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onExtend,
  }) : super(key: key);

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        } else {
          setState(() {
            _showActions = !_showActions;
          });
        }
      },
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Card(
          color: widget.isSelected
              ? AppTheme.primaryText.withOpacity(0.1)
              : AppTheme.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isSelected
                ? BorderSide(color: AppTheme.primaryText, width: 2)
                : BorderSide.none,
          ),
          elevation: widget.isSelected ? 12 : 8,
          shadowColor: Colors.black54,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Чекбокс для режима множественного выбора
                if (widget.isSelectionMode) ...[
                  Checkbox(
                    value: widget.isSelected,
                    onChanged: (value) {
                      widget.onTap?.call();
                    },
                    activeColor: AppTheme.primaryText,
                  ),
                  SizedBox(width: 8),
                ] else ...[
                  Container(
                    width: 6,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.note.isExpired ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.note.disc,
                        style: GoogleFonts.interTight(
                          fontSize: ResponsiveText.subtitle(context),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.note.text,
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.body(context),
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryText,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'До ${widget.note.endDate.day}.${widget.note.endDate.month}.${widget.note.endDate.year} ${widget.note.endLessonTime}',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.small(context),
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Кнопки действий
                if (_showActions && !widget.isSelectionMode) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          if (widget.onEdit != null) {
                            widget.onEdit!();
                          } else {
                            _editNote(context);
                          }
                          setState(() {
                            _showActions = false;
                          });
                        },
                        tooltip: 'Изменить',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (widget.onDelete != null) {
                            widget.onDelete!();
                          } else {
                            _deleteNote(context);
                          }
                          setState(() {
                            _showActions = false;
                          });
                        },
                        tooltip: 'Удалить',
                      ),
                    ],
                  ),
                ] else if (!widget.isSelectionMode) ...[
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.black),
                    onPressed: widget.onExtend ?? () => _extendNote(context),
                    tooltip: 'Продлить',
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
      notesProvider.extendToNextLesson(widget.note, appState.schedule!);
    }
  }

  void _editNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: widget.note),
    );
  }

  void _deleteNote(BuildContext context) {
    Provider.of<NotesProvider>(context, listen: false).deleteNote(widget.note.id);
  }
}
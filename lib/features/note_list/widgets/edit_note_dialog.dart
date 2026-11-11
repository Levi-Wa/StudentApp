import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class EditNoteDialog extends StatefulWidget {
  final Note note;

  const EditNoteDialog({super.key, required this.note});

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);
    final secText = AppTheme.secondaryTextCol(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Редактировать заметку',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.title(context),
                fontWeight: FontWeight.w700,
                color: text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.disc,
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.subtitle(context),
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: 14, color: secText),
                      const SizedBox(width: 4),
                      Text(
                        'Срок: ${widget.note.endDate.day.toString().padLeft(2, '0')}.${widget.note.endDate.month.toString().padLeft(2, '0')}.${widget.note.endDate.year} ${widget.note.endLessonTime}',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveText.small(context),
                          color: secText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Текст заметки',
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: divider),
                ),
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dockActiveAmber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _saveNote();
                    },
                    child: Text(
                      'Сохранить',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    widget.note.text = _textController.text.trim().isEmpty
        ? 'Пустая заметка'
        : _textController.text.trim();
    Provider.of<NotesProvider>(context, listen: false).saveNote(widget.note);
    Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../utils/responsive_text.dart';

class EditNoteDialog extends StatefulWidget {
  final Note note;

  const EditNoteDialog({Key? key, required this.note}) : super(key: key);

  @override
  _EditNoteDialogState createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Редактировать заметку',
              style: GoogleFonts.robotoCondensed(
                fontSize: ResponsiveText.title(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              widget.note.disc,
              style: GoogleFonts.interTight(
                fontSize: ResponsiveText.subtitle(context),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              '${widget.note.endDate.day}.${widget.note.endDate.month}.${widget.note.endDate.year}',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.body(context),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Текст заметки',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _saveNote();
                  },
                  child: Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    widget.note.text = _textController.text.isEmpty ? 'Пустая заметка' : _textController.text;
    Provider.of<NotesProvider>(context, listen: false).saveNote(widget.note);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/models/day_schedule.dart';
import '../../../data/providers/app_state.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../utils/responsive_text.dart';

class CreateNoteDialog extends StatefulWidget {
  @override
  _CreateNoteDialogState createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _textController = TextEditingController();
  String? selectedSubject;
  DateTime? selectedDate;


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
              'Создать заметку',
              style: GoogleFonts.robotoCondensed(
                fontSize: ResponsiveText.title(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final subjects = appState.schedule?.days
                    .expand((day) => day.lessons)
                    .map((lesson) => lesson.disc)
                    .toSet()
                    .toList() ?? [];

                return DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Предмет',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: subjects.map((subject) => 
                    DropdownMenuItem(value: subject, child: Text(subject, overflow: TextOverflow.ellipsis))
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value;
                      selectedDate = null;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Дата',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _selectDate,
              controller: TextEditingController(
                text: selectedDate != null 
                  ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                  : '',
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
                  onPressed: _canSave() ? () {
                    FocusScope.of(context).unfocus();
                    _saveNote();
                  } : null,
                  child: Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canSave() {
    return selectedSubject != null &&
           selectedDate != null;
  }

  void _selectDate() async {
    if (selectedSubject == null) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final availableDates = _getAvailableDates(selectedSubject!, appState.schedule);
    
    final date = await showDatePicker(
      context: context,
      initialDate: availableDates.isNotEmpty ? availableDates.first : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('ru', 'RU'),
      selectableDayPredicate: (date) => availableDates.any((d) => 
        d.year == date.year && d.month == date.month && d.day == date.day
      ),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }
  
  List<DateTime> _getAvailableDates(String subject, schedule) {
    final dates = <DateTime>[];
    
    if (schedule?.days != null) {
      for (final daySchedule in schedule.days) {
        final hasSubject = daySchedule.lessons.any((lesson) => lesson.disc == subject);
        if (hasSubject) {
          try {
            final parts = daySchedule.date.split('.');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final date = DateTime(year, month, day);
              if (date.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
                dates.add(date);
              }
            }
          } catch (e) {
            // ignore invalid dates
          }
        }
      }
    }
    
    return dates;
  }

  void _saveNote() {
    if (!_canSave()) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final dateStr = '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}';
    
    try {
      final daySchedule = appState.schedule?.days.firstWhere(
        (day) => day.date == dateStr,
      );
      
      final lesson = daySchedule?.lessons.firstWhere(
        (l) => l.disc == selectedSubject,
      );
      
      if (lesson != null) {
        final note = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          disc: selectedSubject!,
          text: _textController.text.isEmpty ? 'Пустая заметка' : _textController.text,
          endDate: selectedDate!,
          endLessonTime: lesson.time.split('-')[0].trim(),
          createdAt: DateTime.now(),
        );

        Provider.of<NotesProvider>(context, listen: false).saveNote(note);
        Navigator.pop(context);
      }
    } catch (e) {
      // ignore
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Понедельник';
      case 2: return 'Вторник';
      case 3: return 'Среда';
      case 4: return 'Четверг';
      case 5: return 'Пятница';
      case 6: return 'Суббота';
      case 7: return 'Воскресенье';
      default: return 'Понедельник';
    }
  }
}
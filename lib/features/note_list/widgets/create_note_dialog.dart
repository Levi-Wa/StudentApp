import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/app_state.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class CreateNoteDialog extends StatefulWidget {
  const CreateNoteDialog({super.key});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _textController = TextEditingController();
  final _customSubjectController = TextEditingController();
  final _dateController = TextEditingController();

  String? selectedSubject;
  DateTime? selectedDate;
  bool _isCustomSubject = false;

  @override
  void dispose() {
    _textController.dispose();
    _customSubjectController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Новая заметка',
              style: GoogleFonts.inter(
                fontSize: ResponsiveText.title(context),
                fontWeight: FontWeight.w700,
                color: text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Subject selector or custom input
            Consumer<AppState>(
              builder: (context, appState, child) {
                final subjects = appState.schedule?.days
                        .expand((day) => day.lessons)
                        .map((lesson) => lesson.disc)
                        .where((d) => d.isNotEmpty)
                        .toSet()
                        .toList() ??
                    [];

                if (_isCustomSubject || subjects.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customSubjectController,
                        decoration: InputDecoration(
                          labelText: 'Название предмета / темы',
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
                        onChanged: (_) => setState(() {}),
                      ),
                      if (subjects.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _isCustomSubject = false),
                            child: const Text('Выбрать из расписания',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: InputDecoration(
                        labelText: 'Предмет',
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
                      isExpanded: true,
                      items: subjects
                          .map((subject) => DropdownMenuItem(
                                value: subject,
                                child: Text(
                                  subject,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: text,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _isCustomSubject = true),
                        child: const Text('Ввести своё название',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Date picker
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Срок выполнения (дата)',
                hintText: 'Выберите дату',
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
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
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Note text
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Текст заметки / задание',
                hintText: 'Что нужно сделать...',
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
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),

            // Action buttons
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
                    onPressed: _canSave()
                        ? () {
                            FocusScope.of(context).unfocus();
                            _saveNote();
                          }
                        : null,
                    child: Text(
                      'Создать',
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

  bool _canSave() {
    final effectiveSubject =
        _isCustomSubject ? _customSubjectController.text.trim() : selectedSubject;
    return effectiveSubject != null &&
        effectiveSubject.isNotEmpty &&
        selectedDate != null;
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  void _saveNote() {
    if (!_canSave()) return;

    final effectiveSubject =
        _isCustomSubject ? _customSubjectController.text.trim() : selectedSubject!;

    final appState = Provider.of<AppState>(context, listen: false);
    final dateStr =
        '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}';

    String endLessonTime = '09:00';
    try {
      final daySchedule = appState.schedule?.days
          .where((day) => day.date == dateStr)
          .firstOrNull;

      final lesson = daySchedule?.lessons
          .where((l) => l.disc == effectiveSubject)
          .firstOrNull;

      if (lesson != null && lesson.time.isNotEmpty) {
        endLessonTime = lesson.time.split('-')[0].trim();
      }
    } catch (_) {}

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      disc: effectiveSubject,
      text: _textController.text.trim().isEmpty
          ? 'Заметка без текста'
          : _textController.text.trim(),
      endDate: selectedDate!,
      endLessonTime: endLessonTime,
      createdAt: DateTime.now(),
    );

    Provider.of<NotesProvider>(context, listen: false).saveNote(note);
    Navigator.pop(context);
  }
}

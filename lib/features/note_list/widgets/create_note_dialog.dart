import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/note.dart';
import '../../../data/providers/app_state.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class CreateNoteDialog extends StatefulWidget {
  final String? initialSubject;
  final String? initialTeacher;
  final String? initialTime;
  final DateTime? initialDate;

  const CreateNoteDialog({
    super.key,
    this.initialSubject,
    this.initialTeacher,
    this.initialTime,
    this.initialDate,
  });

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _textController = TextEditingController();
  final _customSubjectController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String? selectedSubject;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isCustomSubject = false;

  @override
  void initState() {
    super.initState();
    selectedSubject = widget.initialSubject;
    selectedDate = widget.initialDate ?? DateTime.now();
    _dateController.text =
        '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}';

    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      _timeController.text = widget.initialTime!;
      try {
        final parts = widget.initialTime!.split(':');
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {
        selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
    } else {
      selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _timeController.text = '09:00';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _customSubjectController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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
            if (widget.initialTeacher != null && widget.initialTeacher!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppTheme.dockActiveAmber),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.initialTeacher!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dockActiveAmber,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

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

                if (widget.initialSubject != null &&
                    widget.initialSubject!.isNotEmpty &&
                    !subjects.contains(widget.initialSubject)) {
                  subjects.insert(0, widget.initialSubject!);
                }

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

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Дата сдачи',
                      hintText: 'Выберите дату',
                      suffixIcon:
                          const Icon(Icons.calendar_today_rounded, size: 18),
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Время',
                      hintText: '09:00',
                      suffixIcon:
                          const Icon(Icons.access_time_rounded, size: 18),
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
                    onTap: _selectTime,
                  ),
                ),
              ],
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

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
        final hour = picked.hour.toString().padLeft(2, '0');
        final min = picked.minute.toString().padLeft(2, '0');
        _timeController.text = '$hour:$min';
      });
    }
  }

  void _saveNote() {
    if (!_canSave()) return;

    final effectiveSubject =
        _isCustomSubject ? _customSubjectController.text.trim() : selectedSubject!;

    final timeStr = _timeController.text.trim().isNotEmpty
        ? _timeController.text.trim()
        : '09:00';

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      disc: effectiveSubject,
      text: _textController.text.trim().isEmpty
          ? 'Заметка без текста'
          : _textController.text.trim(),
      endDate: selectedDate!,
      endLessonTime: timeStr,
      createdAt: DateTime.now(),
    );

    Provider.of<NotesProvider>(context, listen: false).saveNote(note);
    Navigator.pop(context);
  }
}

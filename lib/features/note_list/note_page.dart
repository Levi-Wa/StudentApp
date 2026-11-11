import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/note.dart';
import '../../data/providers/notes_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';
import 'widgets/note_card.dart';
import 'widgets/create_note_dialog.dart';
import 'widgets/edit_note_dialog.dart';
import 'widgets/date_filter.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  DateTime? selectedDate;
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadNotes();
    });
  }

  void _showCreateNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateNoteDialog(),
    );
  }

  void _editNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );
  }

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _deleteSelectedNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление заметок'),
        content: Text(
          'Удалить выбранные заметки (${_selectedNoteIds.length} шт.)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              final provider =
                  Provider.of<NotesProvider>(context, listen: false);
              for (final id in _selectedNoteIds) {
                provider.deleteNote(id);
              }
              _cancelSelection();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _getDayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }

  String _getMonthShort(int month) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    final bg = AppTheme.bg(context);
    final cardBg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final divider = AppTheme.divider(context);

    final now = selectedDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: _isSelectionMode
            ? Text(
                'Выбрано: ${_selectedNoteIds.length}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              )
            : Row(
                children: [
                  Text(
                    'Заметки',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: text,
                    ),
                  ),
                  const Spacer(),
                  // Top right date badge matching Image 1 Tasks screen
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getDayShort(now.weekday),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: subtext,
                            ),
                          ),
                          Text(
                            _getMonthShort(now.month),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: subtext,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${now.day}',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: text,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () {
            if (_isSelectionMode) {
              _cancelSelection();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              tooltip: 'Удалить выбранные',
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: _deleteSelectedNotes,
            ),
            IconButton(
              tooltip: 'Отмена',
              icon: Icon(Icons.close_rounded, color: text),
              onPressed: _cancelSelection,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Добавить заметку',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.dockActiveAmber,
                size: 24,
              ),
              onPressed: _showCreateNoteDialog,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateNoteDialog,
        backgroundColor: AppTheme.dockActiveAmber,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Заметка',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Horizontal week filter strip
          DateFilter(
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
          Divider(height: 1, color: divider),

          // Notes List
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) {
                var notes = notesProvider.notes;

                // Filter by date if selected
                if (selectedDate != null) {
                  notes = notes.where((note) {
                    return note.endDate.year == selectedDate!.year &&
                        note.endDate.month == selectedDate!.month &&
                        note.endDate.day == selectedDate!.day;
                  }).toList();
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppTheme.dockActiveAmber
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              size: 52,
                              color: AppTheme.dockActiveAmber,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            selectedDate != null
                                ? 'На эту дату задач нет'
                                : 'У вас пока нет заметок',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.title(context),
                              fontWeight: FontWeight.w700,
                              color: text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedDate != null
                                ? 'Выберите другую дату или добавьте новую задачу'
                                : 'Нажмите кнопку «Заметка», чтобы записать задание к паре',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.body(context),
                              color: subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 90),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isSelected = _selectedNoteIds.contains(note.id);

                    return NoteCard(
                      key: ValueKey(note.id),
                      note: note,
                      index: index,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedNoteIds.add(note.id);
                          });
                        }
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(note.id);
                        } else {
                          _editNote(note);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/note.dart';
import '../../data/providers/notes_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(
                'Выбрано: ${_selectedNoteIds.length}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              )
            : Text(
                'Заметки',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
              icon: const Icon(Icons.close_rounded),
              onPressed: _cancelSelection,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Добавить заметку',
              icon: const Icon(Icons.add_rounded, color: AppTheme.primaryAccent),
              onPressed: _showCreateNoteDialog,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateNoteDialog,
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Заметка',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Date Filter Strip
          DateFilter(
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
          const Divider(height: 1),

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
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.note_alt_outlined,
                              size: 56,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            selectedDate != null
                                ? 'На эту дату заметок нет'
                                : 'У вас пока нет заметок',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.title(context),
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedDate != null
                                ? 'Выберите другую дату или добавьте новую заметку'
                                : 'Нажмите кнопку «Заметка», чтобы записать задание к паре',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.body(context),
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final isSelected = _selectedNoteIds.contains(note.id);

                    return NoteCard(
                      key: ValueKey(note.id),
                      note: note,
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

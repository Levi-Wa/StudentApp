import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:circular_menu/circular_menu.dart';
import '../../data/models/note.dart';
import '../../data/providers/app_state.dart';
import '../../data/providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';
import 'widgets/note_card.dart';
import 'widgets/create_note_dialog.dart';
import 'widgets/edit_note_dialog.dart';
import 'widgets/date_filter.dart';

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  String? selectedSubject;
  DateTime? selectedDate;
  bool _isSelectionMode = false;
  Set<String> _selectedNoteIds = {};
  Note? _selectedSingleNote;

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'января';
      case 2: return 'февраля';
      case 3: return 'марта';
      case 4: return 'апреля';
      case 5: return 'мая';
      case 6: return 'июня';
      case 7: return 'июля';
      case 8: return 'августа';
      case 9: return 'сентября';
      case 10: return 'октября';
      case 11: return 'ноября';
      case 12: return 'декабря';
      default: return 'января';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 45,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getMonthName(DateTime.now().month).substring(0, 3)} ',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${DateTime.now().year.toString().substring(2)}',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${DateTime.now().day}',
                            style: GoogleFonts.oswald(
                              fontSize: ResponsiveText.title(context),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Заметки',
                        style: GoogleFonts.robotoCondensed(
                          fontSize: ResponsiveText.headline(context),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: CircularMenu(
        alignment: Alignment.bottomRight,
        radius: _isSelectionMode ? 140 : 100,
        toggleButtonColor: Colors.black,
        toggleButtonIconColor: Colors.white,
        toggleButtonSize: 28,
        toggleButtonMargin: 16,
        backgroundWidget: Container(),
        items: [
          if (!_isSelectionMode) ...[
            CircularMenuItem(
              icon: Icons.add,
              color: Colors.black,
              iconColor: Colors.white,
              onTap: () => _showCreateNoteDialog(),
            ),
            CircularMenuItem(
              icon: Icons.arrow_back,
              color: Colors.black,
              iconColor: Colors.white,
              onTap: () => Navigator.pop(context),
            ),
          ] else ...[
            if (_selectedNoteIds.length == 1 && _selectedSingleNote != null)
              CircularMenuItem(
                icon: Icons.edit,
                color: Colors.black,
                iconColor: Colors.white,
                onTap: () {
                  final note = _selectedSingleNote!;
                  _cancelSelection();
                  _editNote(note);
                },
              ),
            CircularMenuItem(
              icon: Icons.delete,
              color: Colors.black,
              iconColor: Colors.white,
              onTap: () => _deleteSelectedNotes(),
            ),
            CircularMenuItem(
              icon: Icons.cancel,
              color: Colors.black,
              iconColor: Colors.white,
              onTap: () => _cancelSelection(),
            ),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBackground,
              AppTheme.secondaryBackground,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            DateFilter(
              onDateSelected: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final subjects = appState.schedule?.days
                      .expand((day) => day.lessons)
                      .map((lesson) => lesson.disc)
                      .toSet()
                      .toList() ?? [];
                  
                  return Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: InputDecoration(
                        labelText: 'Фильтр по предмету',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null, 
                          child: Text('Все предметы', 
                            style: TextStyle(fontSize: ResponsiveText.body(context)),
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                        ...subjects.map((subject) => 
                          DropdownMenuItem(
                            value: subject, 
                            child: Text(subject, 
                              style: TextStyle(fontSize: ResponsiveText.body(context)),
                              overflow: TextOverflow.ellipsis
                            )
                          )
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer<NotesProvider>(
                builder: (context, notesProvider, child) {
                  var notes = notesProvider.notes;
                  
                  if (selectedDate != null) {
                    notes = notes.where((note) => 
                      note.endDate.year == selectedDate!.year &&
                      note.endDate.month == selectedDate!.month &&
                      note.endDate.day == selectedDate!.day
                    ).toList();
                  }
                  
                  if (selectedSubject != null) {
                    notes = notes.where((note) => note.disc == selectedSubject).toList();
                  }
                  
                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет заметок',
                        style: GoogleFonts.inter(fontSize: ResponsiveText.subtitle(context)),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 25),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        isSelected: _selectedNoteIds.contains(note.id),
                        isSelectionMode: _isSelectionMode,
                        onLongPress: () => _onNoteLongPress(note),
                        onTap: () => _onNoteTap(note),
                        onEdit: () => _editNote(note),
                        onDelete: () => _deleteNote(note.id),
                        onExtend: () => _extendNote(note),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateNoteDialog(),
    );
  }

  void _onNoteLongPress(Note note) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedNoteIds.add(note.id);
        _selectedSingleNote = note;
      });
    }
  }

  void _onNoteTap(Note note) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedNoteIds.contains(note.id)) {
          _selectedNoteIds.remove(note.id);
          if (_selectedNoteIds.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedNoteIds.add(note.id);
        }
        if (_selectedNoteIds.length == 1) {
          _selectedSingleNote = note;
        } else {
          _selectedSingleNote = null;
        }
      });
    }
  }

  void _editNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );
  }

  void _deleteNote(String noteId) {
    Provider.of<NotesProvider>(context, listen: false).deleteNote(noteId);
  }

  void _extendNote(Note note) {
    final appState = Provider.of<AppState>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    if (appState.schedule != null) {
      notesProvider.extendToNextLesson(note, appState.schedule!);
    }
  }

  Future<void> _deleteSelectedNotes() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final idsToDelete = _selectedNoteIds.toList();
    final deletedCount = idsToDelete.length;

    // Удаляем последовательно, чтобы корректно обрабатывать возможные ошибки
    for (final noteId in idsToDelete) {
      try {
        await notesProvider.deleteNote(noteId);
      } catch (e) {
        print('NotePage: Ошибка удаления заметки $noteId: $e');
      }
    }
    setState(() {
      _selectedNoteIds.clear();
      _isSelectionMode = false;
      _selectedSingleNote = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удалено заметок: $deletedCount'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _cancelSelection() {
    setState(() {
      _selectedNoteIds.clear();
      _isSelectionMode = false;
      _selectedSingleNote = null;
    });
  }
}

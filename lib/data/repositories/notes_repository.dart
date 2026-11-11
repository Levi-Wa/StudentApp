import 'package:hive/hive.dart';
import '../models/note.dart';
import '../models/full_schedule.dart';
import '../models/lesson.dart';

class NotesRepository {
  static const String _notesBox = 'notes';

  Future<Box<Note>> _getBox() async {
    if (Hive.isBoxOpen(_notesBox)) {
      return Hive.box<Note>(_notesBox);
    }
    return await Hive.openBox<Note>(_notesBox);
  }

  Future<void> saveNote(Note note) async {
    final box = await _getBox();
    await box.put(note.id, note);
  }

  Future<List<Note>> getNotes() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<List<Note>> getNotesForDate(DateTime date) async {
    final notes = await getNotes();
    return notes
        .where((note) =>
            note.endDate.year == date.year &&
            note.endDate.month == date.month &&
            note.endDate.day == date.day)
        .toList();
  }

  Future<List<Note>> getNotesForSubject(String subject) async {
    final notes = await getNotes();
    return notes.where((note) => note.disc == subject).toList();
  }

  Future<void> deleteNote(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> extendToNextLesson(Note note, FullSchedule schedule) async {
    final nextLesson = _findNextLesson(note.disc, note.endDate, schedule);
    if (nextLesson != null) {
      note.endDate = nextLesson['date'] as DateTime;
      note.endLessonTime = nextLesson['time'] as String;
      await saveNote(note);
    }
  }

  Map<String, dynamic>? _findNextLesson(
      String subject, DateTime currentDate, FullSchedule schedule) {
    final currentDateStr =
        '${currentDate.day.toString().padLeft(2, '0')}.${currentDate.month.toString().padLeft(2, '0')}.${currentDate.year}';

    // Find current date index in schedule
    int currentIndex = -1;
    for (int i = 0; i < schedule.days.length; i++) {
      if (schedule.days[i].date == currentDateStr) {
        currentIndex = i;
        break;
      }
    }

    // Look for next lesson with same subject starting from next day
    for (int i = currentIndex + 1; i < schedule.days.length; i++) {
      final daySchedule = schedule.days[i];

      Lesson? lesson;
      try {
        lesson = daySchedule.lessons.firstWhere(
          (l) => l.disc == subject,
        );
      } catch (_) {
        lesson = null;
      }

      if (lesson != null) {
        try {
          final parts = daySchedule.date.split('.');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final date = DateTime(year, month, day);

            return {
              'date': date,
              'time': lesson.time.split('-')[0].trim(),
            };
          }
        } catch (_) {}
      }
    }

    return null;
  }

  Future<void> cleanExpiredNotes() async {
    // Optionally keep old notes or clean up
  }
}

import 'package:hive/hive.dart';
import '../models/note.dart';
import '../models/full_schedule.dart';

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

  Future<Map<String, dynamic>> extendToNextLesson(Note note, FullSchedule schedule) async {
    final nextLesson = _findNextLesson(note.disc, note.endDate, schedule);
    if (nextLesson != null) {
      note.endDate = nextLesson['date'] as DateTime;
      note.endLessonTime = nextLesson['time'] as String;
    } else {
      // Fallback: precisely 1 week (+7 days) later at same lesson time
      note.endDate = note.endDate.add(const Duration(days: 7));
    }
    await saveNote(note);
    return {
      'date': note.endDate,
      'time': note.endLessonTime,
      'isScheduleMatch': nextLesson != null,
    };
  }

  Map<String, dynamic>? _findNextLesson(
      String subject, DateTime currentDate, FullSchedule schedule) {
    final cleanSubject = subject.trim().toLowerCase();
    final cleanCurrentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

    DateTime? earliestDate;
    String? earliestTime;

    for (final day in schedule.days) {
      DateTime? dayDate;
      try {
        final parts = day.date.split('.');
        if (parts.length == 3) {
          dayDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else if (parts.length == 2) {
          dayDate = DateTime(currentDate.year, int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}

      if (dayDate == null) continue;

      // Must be chronologically after the current deadline date
      if (!dayDate.isAfter(cleanCurrentDate)) continue;

      // Find matching lesson in this day
      for (final l in day.lessons) {
        if (l.disc.trim().toLowerCase() == cleanSubject) {
          if (earliestDate == null || dayDate.isBefore(earliestDate)) {
            earliestDate = dayDate;
            earliestTime = l.time.isNotEmpty ? l.time.split('-')[0].trim() : '09:00';
          }
          break;
        }
      }
    }

    if (earliestDate != null) {
      return {
        'date': earliestDate,
        'time': earliestTime ?? '09:00',
      };
    }

    return null;
  }

  Future<void> cleanExpiredNotes() async {
    // Optionally keep old notes or clean up
  }
}

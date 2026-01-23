import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/full_schedule.dart';
import '../repositories/notes_repository.dart';
import '../services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final NotesRepository _repository = NotesRepository();
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  Future<void> loadNotes() async {
    await _repository.cleanExpiredNotes();
    _notes = await _repository.getNotes();
    notifyListeners();
  }

  Future<void> saveNote(Note note) async {
    // Отменяем старое уведомление, если заметка редактируется
    final existingNote = _notes.firstWhere(
      (n) => n.id == note.id,
      orElse: () => Note(
        id: '',
        disc: '',
        text: '',
        endDate: DateTime.now(),
        endLessonTime: '',
        createdAt: DateTime.now(),
      ),
    );
    
    if (existingNote.id.isNotEmpty) {
      final oldNotificationId = NotificationService.generateNoteNotificationId(existingNote.id);
      await NotificationService.cancelNotification(oldNotificationId);
    }
    
    await _repository.saveNote(note);
    await _scheduleNoteNotification(note);
    await loadNotes();
  }
  
  Future<void> _scheduleNoteNotification(Note note) async {
    final period = await NotificationService.getNotificationPeriod();
    final notificationTime = note.endDate.subtract(Duration(days: period));
    
    if (notificationTime.isAfter(DateTime.now())) {
      final notificationId = NotificationService.generateNoteNotificationId(note.id);
      
      await NotificationService.scheduleNoteNotification(
        'Истекает срок заметки',
        'Заметка по ${note.disc}: ${note.text.length > 50 ? note.text.substring(0, 50) + "..." : note.text}',
        notificationTime,
        notificationId: notificationId,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    // Отменяем уведомление при удалении заметки
    final notificationId = NotificationService.generateNoteNotificationId(id);
    try {
      await NotificationService.cancelNotification(notificationId);
    } catch (e) {
      // Не блокируем удаление заметки из-за проблем с уведомлениями
      print('NotesProvider: Ошибка отмены уведомления для заметки $id: $e');
    }
    
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> extendToNextLesson(Note note, FullSchedule schedule) async {
    // Отменяем старое уведомление
    final oldNotificationId = NotificationService.generateNoteNotificationId(note.id);
    await NotificationService.cancelNotification(oldNotificationId);
    
    await _repository.extendToNextLesson(note, schedule);
    
    // Загружаем обновленную заметку и планируем новое уведомление
    await loadNotes();
    final updatedNote = _notes.firstWhere(
      (n) => n.id == note.id,
      orElse: () => note,
    );
    
    if (updatedNote.id == note.id) {
      await _scheduleNoteNotification(updatedNote);
    }
  }
}
import 'package:flutter/material.dart';
import '../models/full_schedule.dart';
import '../models/day_schedule.dart';
import '../models/lesson.dart';
import '../models/group.dart';
import '../repositories/schedule_repository.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  FullSchedule? _schedule;
  List<Group> _allGroups = [];
  List<Group> _filteredGroups = [];
  bool _isLoading = false;
  String? _selectedDay;
  bool _initialized = false;

  FullSchedule? get schedule => _schedule;
  List<Group> get groups => _filteredGroups;
  bool get isLoading => _isLoading;
  String? get selectedDay => _selectedDay;
  
  List<String> get formEduOptions => _allGroups.map((g) => g.formEdu).toSet().toList();
  
  List<String> getCourseOptions(String? formEdu) {
    if (formEdu == null) return [];
    return _allGroups
        .where((g) => g.formEdu == formEdu)
        .map((g) => g.course.toString())
        .toSet()
        .toList();
  }
  
  void filterGroups(String? formEdu, String? course) {
    final newFiltered = <Group>[];
    if (formEdu != null && course != null) {
      newFiltered.addAll(_allGroups
          .where((g) => g.formEdu == formEdu && g.course.toString() == course));
    }

    // Вызываем notifyListeners только если список действительно изменился
    if (_filteredGroups.length != newFiltered.length ||
        !_filteredGroups.every((group) => newFiltered.contains(group))) {
      _filteredGroups = newFiltered;
    notifyListeners();
    }
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allGroups = await _repository.getGroups();
    } catch (e) {
      print('Error loading groups: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedule(int groupId, String groupName) async {
    print('AppState: Начало загрузки расписания для группы $groupName (ID: $groupId)');
    _isLoading = true;
    notifyListeners();
    
    try {
      print('AppState: Сохраняю выбор группы...');
      await _repository.saveGroupSelection(groupId, groupName);
      
      print('AppState: Запрашиваю расписание с сервера...');
      _schedule = await _repository.getSchedule(groupId);
      
      if (_schedule != null) {
        print('AppState: Получено расписание для группы ${_schedule!.group}');
        print('AppState: Количество дней: ${_schedule!.days.length}');
        
        for (var day in _schedule!.days) {
          print('AppState: ${day.dayOfWeek} (${day.date}): ${day.lessons.length} занятий');
          for (var lesson in day.lessons) {
            print('  - ${lesson.time}: ${lesson.disc} (ауд. ${lesson.aud}, ${lesson.vidZan})');
          }
        }
        
        if (_schedule!.days.isNotEmpty) {
          final today = DateTime.now();
          final todayName = _getDayName(today.weekday);
          
          final todaySchedule = _schedule!.days.firstWhere(
            (day) => day.dayOfWeek == todayName,
            orElse: () => _schedule!.days.first,
          );
          
          _selectedDay = todaySchedule.dayOfWeek;
          print('AppState: Выбран день: $_selectedDay');
        } else {
          print('AppState: Нет дней в расписании');
        }
        
        // Временно отключаем планирование уведомлений для тестирования
        // await _scheduleUpcomingLessonsNotifications();
        print('AppState: Планирование уведомлений временно отключено');
      } else {
        print('AppState: Получено пустое расписание');
      }
    } catch (e) {
      print('AppState: Ошибка загрузки расписания: $e');
      throw e;
    }
    
    _isLoading = false;
    print('AppState: Загрузка завершена - loadSchedule ЗАВЕРШЕН');
    // НЕ вызываем notifyListeners() сразу, чтобы избежать проблем с Consumer'ами
  }

  // Метод для вызова notifyListeners() после успешной навигации
  void notifyScheduleLoaded() {
    print('AppState: Вызываю notifyListeners() после успешной навигации');
    notifyListeners();
    print('AppState: notifyListeners() выполнен после навигации');
  }

  void selectDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  DateTime _selectedWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  
  DateTime get selectedWeekStart => _selectedWeekStart;
  
  void selectWeek(DateTime weekStart) {
    _selectedWeekStart = weekStart;
    // Обновляем выбранный день для новой недели
    if (_schedule != null && _schedule!.days.isNotEmpty) {
      final weekDays = currentWeekDays;
      if (weekDays.isNotEmpty) {
        _selectedDay = weekDays.first.dayOfWeek;
      }
    }
    notifyListeners();
  }
  
  List<DaySchedule> _cachedWeekDays = [];
  DateTime? _lastWeekStart;
  FullSchedule? _lastSchedule;
  
  List<DaySchedule> get currentWeekDays {
    // Используем кэширование для оптимизации
    if (_schedule == null || _schedule!.days.isEmpty) {
      _cachedWeekDays = [];
      return _cachedWeekDays;
    }

    // Если неделя и расписание не изменились, возвращаем кэш
    if (_selectedWeekStart == _lastWeekStart && _schedule == _lastSchedule) {
      return _cachedWeekDays;
    }

    // Обновляем кэш
    _lastWeekStart = _selectedWeekStart;
    _lastSchedule = _schedule;
    
    final endOfWeek = _selectedWeekStart.add(Duration(days: 4)); // Пн-Пт
    
    _cachedWeekDays = _schedule!.days.where((day) {
      try {
        final parts = day.date.split('.');
        if (parts.length == 3) {
          final dayDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          return dayDate.isAfter(_selectedWeekStart.subtract(Duration(days: 1))) && 
                 dayDate.isBefore(endOfWeek.add(Duration(days: 1)));
        }
      } catch (e) {
        return false;
      }
      return false;
    }).toList();

    return _cachedWeekDays;
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

  Future<bool> hasSelectedGroup() async {
    final groupId = await _repository.getSavedGroupId();
    final groupName = await _repository.getSavedGroupName();
    print('AppState: hasSelectedGroup - groupId: $groupId, groupName: $groupName');
    return groupId != null;
  }

  Future<void> initializeApp() async {
    print('AppState: === НАЧАЛО ИНИЦИАЛИЗАЦИИ ===');
    if (_initialized) {
      print('AppState: Уже инициализирован, пропускаю');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Загружаем сохраненную группу и расписание
      print('AppState: Загружаю сохраненную группу...');
      final groupId = await _repository.getSavedGroupId();
      final groupName = await _repository.getSavedGroupName();
      print('AppState: hasSelectedGroup - groupId: $groupId, groupName: $groupName');
      
      if (groupId != null && groupName != null) {
        print('AppState: Группа найдена, загружаю кэшированное расписание...');
        // Загружаем кэшированное расписание
        _schedule = await _repository.getSchedule(groupId);
        
        if (_schedule != null && _schedule!.days.isNotEmpty) {
          print('AppState: Кэшированное расписание загружено, дней: ${_schedule!.days.length}');
          final today = DateTime.now();
          final todayName = _getDayName(today.weekday);
          
          final todaySchedule = _schedule!.days.firstWhere(
            (day) => day.dayOfWeek == todayName,
            orElse: () => _schedule!.days.first,
          );
          
          _selectedDay = todaySchedule.dayOfWeek;
          print('AppState: Выбран день: $_selectedDay');

          // Временно отключаем планирование уведомлений для тестирования
          // await _scheduleUpcomingLessonsNotifications();
          print('AppState: Планирование уведомлений в initializeApp временно отключено');
        } else {
          print('AppState: Кэшированное расписание пустое или null, schedule: $_schedule');
        }
      } else {
        print('AppState: Сохраненная группа не найдена');
      }

      print('AppState: Загружаю группы...');
      await loadGroups();
      _initialized = true;
      print('AppState: Инициализация завершена успешно');
    } catch (e) {
      print('AppState: Ошибка инициализации: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> forceUpdateSchedule() async {
    final groupId = await _repository.getSavedGroupId();
    final groupName = await _repository.getSavedGroupName();
    
    if (groupId != null && groupName != null) {
      final oldSchedule = _schedule;
      await loadSchedule(groupId, groupName);
      await _checkScheduleChanges(oldSchedule, _schedule);
    }
  }
  
  Future<void> _checkScheduleChanges(FullSchedule? oldSchedule, FullSchedule? newSchedule) async {
    if (oldSchedule == null || newSchedule == null) return;
    
    bool hasChanges = false;
    String changeMessage = '';
    
    // Проверка изменений по количеству дней
    if (oldSchedule.days.length != newSchedule.days.length) {
      hasChanges = true;
      changeMessage = 'Изменено количество дней в расписании';
    } else {
      // Проверка изменений в занятиях
      for (var newDay in newSchedule.days) {
        final oldDay = oldSchedule.days.firstWhere(
          (d) => d.date == newDay.date,
          orElse: () => DaySchedule(date: '', dayOfWeek: '', lessons: []),
        );
        
        if (oldDay.date.isEmpty) {
          hasChanges = true;
          changeMessage = 'Добавлен новый день в расписании';
          break;
        }
        
        if (oldDay.lessons.length != newDay.lessons.length) {
          hasChanges = true;
          changeMessage = 'Изменено количество занятий на ${newDay.dayOfWeek}';
          break;
        }
        
        // Проверка изменений в конкретных занятиях
        for (var newLesson in newDay.lessons) {
          final oldLesson = oldDay.lessons.firstWhere(
            (l) => l.time == newLesson.time && l.disc == newLesson.disc,
            orElse: () => Lesson(
              time: '',
              disc: '',
              prepod: '',
              aud: '',
              vidZan: '',
              dayOfWeek: '',
            ),
          );
          
          if (oldLesson.time.isEmpty || 
              oldLesson.aud != newLesson.aud || 
              oldLesson.prepod != newLesson.prepod) {
            hasChanges = true;
            changeMessage = 'Изменения в расписании на ${newDay.dayOfWeek}';
            break;
          }
        }
        
        if (hasChanges) break;
      }
    }
    
    if (hasChanges) {
      await _sendScheduleChangeNotification('Изменение в расписании', changeMessage);
      // Перепланируем уведомления о занятиях
      await _scheduleUpcomingLessonsNotifications();
    }
  }
  
  Future<void> _sendScheduleChangeNotification(String title, String body) async {
    await NotificationService.scheduleScheduleNotification(
      title,
      body,
      DateTime.now().add(Duration(seconds: 1)), // Немедленно
    );
  }
  
  Future<void> _scheduleUpcomingLessonsNotifications() async {
    if (_schedule == null) return;

    try {
      // Отменяем старые уведомления о занятиях
      await NotificationService.cancelAllLessonNotifications();
    } catch (e) {
      print('Ошибка при отмене уведомлений о занятиях: $e');
      // Продолжаем работу несмотря на ошибку
    }
    
    final now = DateTime.now();
    final period = await NotificationService.getNotificationPeriod();
    
    try {
      // Планируем уведомления на ближайшие дни (в зависимости от периода)
      for (var day in _schedule!.days) {
        try {
          final parts = day.date.split('.');
          if (parts.length == 3) {
            final dayDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );

            // Планируем только для будущих дней в пределах периода
            if (dayDate.isAfter(now.subtract(Duration(days: 1))) &&
                dayDate.isBefore(now.add(Duration(days: period + 1)))) {

              for (var lesson in day.lessons) {
                try {
                  final lessonTime = _parseLessonTime(lesson.time, dayDate);

                  if (lessonTime != null && lessonTime.isAfter(now)) {
                    // Планируем уведомление за 15 минут до начала занятия
                    final notificationTime = lessonTime.subtract(Duration(minutes: 15));

                    if (notificationTime.isAfter(now)) {
                      final notificationId = NotificationService.generateLessonNotificationId(
                        day.date,
                        lesson.time,
                      );

                      await NotificationService.scheduleLessonNotification(
                        'Скоро занятие',
                        '${lesson.disc}\n${lesson.time}, ауд. ${lesson.aud}',
                        notificationTime,
                        notificationId: notificationId,
                      );
                    }
                  }
                } catch (e) {
                  print('Ошибка планирования уведомления для занятия ${lesson.disc}: $e');
                }
              }
            }
          }
        } catch (e) {
          print('Ошибка планирования уведомления для дня ${day.date}: $e');
        }
      }
    } catch (e) {
      print('Критическая ошибка при планировании уведомлений о занятиях: $e');
    }
  }
  
  DateTime? _parseLessonTime(String timeStr, DateTime dayDate) {
    try {
      final parts = timeStr.split('-');
      if (parts.isNotEmpty) {
        final timeParts = parts[0].trim().split(':');
        if (timeParts.length == 2) {
          final hours = int.parse(timeParts[0]);
          final minutes = int.parse(timeParts[1]);
          
          return DateTime(
            dayDate.year,
            dayDate.month,
            dayDate.day,
            hours,
            minutes,
          );
        }
      }
    } catch (e) {
      print('Ошибка парсинга времени: $e');
    }
    return null;
  }
  
  Future<void> resetApp() async {
    // Отменяем все уведомления при сбросе
    await NotificationService.cancelAllNotifications();
    
    await _repository.clearAllData();
    _schedule = null;
    _selectedDay = null;
    _initialized = false;
    notifyListeners();
  }
  
  Future<String?> getCurrentGroupName() async {
    return await _repository.getSavedGroupName();
  }
}

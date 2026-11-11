import 'package:flutter/material.dart';
import '../models/full_schedule.dart';
import '../models/day_schedule.dart';
import '../models/group.dart';
import '../repositories/schedule_repository.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  FullSchedule? _schedule;
  List<Group> _allGroups = [];
  List<Group> _filteredGroups = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _selectedDay;
  String? _selectedDateStr;
  String? _currentGroupName;
  int? _currentGroupId;
  DateTime? _lastUpdated;
  String? _lastSyncError;
  bool _initialized = false;

  late DateTime _selectedWeekStart;

  AppState() {
    _selectedWeekStart = getMondayOfWeek(DateTime.now());
  }

  FullSchedule? get schedule => _schedule;
  List<Group> get groups => _filteredGroups;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get selectedDay => _selectedDay;
  String? get selectedDateStr => _selectedDateStr;
  String? get currentGroupName => _currentGroupName;
  int? get currentGroupId => _currentGroupId;
  DateTime? get lastUpdated => _lastUpdated;
  String? get lastSyncError => _lastSyncError;
  DateTime get selectedWeekStart => _selectedWeekStart;

  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime getMondayOfWeek(DateTime dt) {
    final clean = normalizeDate(dt);
    return clean.subtract(Duration(days: clean.weekday - 1));
  }

  List<String> get formEduOptions =>
      _allGroups.map((g) => g.formEdu).where((e) => e.isNotEmpty).toSet().toList();

  List<String> getCourseOptions(String? formEdu) {
    if (formEdu == null) return [];
    return _allGroups
        .where((g) => g.formEdu == formEdu)
        .map((g) => g.course.toString())
        .toSet()
        .toList()
      ..sort();
  }

  void filterGroups(String? formEdu, String? course) {
    final newFiltered = <Group>[];
    if (formEdu != null && course != null) {
      newFiltered.addAll(_allGroups.where(
          (g) => g.formEdu == formEdu && g.course.toString() == course));
    } else if (formEdu != null) {
      newFiltered.addAll(_allGroups.where((g) => g.formEdu == formEdu));
    }

    _filteredGroups = newFiltered;
    notifyListeners();
  }

  Future<void> loadGroups() async {
    try {
      _allGroups = await _repository.getGroups();
    } catch (_) {
      // Group loading error handled gracefully
    }
  }

  Future<void> loadSchedule(int groupId, String groupName,
      {bool forceUpdate = false}) async {
    _isLoading = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      await _repository.saveGroupSelection(groupId, groupName);
      _currentGroupId = groupId;
      _currentGroupName = groupName;

      _schedule = await _repository.getSchedule(groupId, forceUpdate: forceUpdate);
      _lastUpdated = await _repository.getLastUpdated() ?? DateTime.now();

      _updateSelectedDayForCurrentSchedule();
      _scheduleUpcomingLessonsNotifications();
    } catch (e) {
      _lastSyncError = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Принудительное обновление расписания с сервера (Pull-to-refresh или кнопка)
  Future<bool> forceUpdateSchedule() async {
    final groupId = _currentGroupId ?? await _repository.getSavedGroupId();
    final groupName = _currentGroupName ?? await _repository.getSavedGroupName();

    if (groupId == null || groupName == null) return false;

    _isRefreshing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final oldSchedule = _schedule;
      final freshSchedule =
          await _repository.getSchedule(groupId, forceUpdate: true);

      _schedule = freshSchedule;
      _lastUpdated = DateTime.now();

      await _checkScheduleChanges(oldSchedule, _schedule);
      _updateSelectedDayForCurrentSchedule();
      _scheduleUpcomingLessonsNotifications();

      _isRefreshing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastSyncError = e.toString();
      _isRefreshing = false;
      notifyListeners();
      return false;
    }
  }

  void selectDay(String day, {String? dateStr}) {
    _selectedDay = day;
    if (dateStr != null) {
      _selectedDateStr = dateStr;
    } else {
      final match = currentWeekDays.where((d) => d.dayOfWeek == day).firstOrNull;
      _selectedDateStr = match?.date;
    }
    notifyListeners();
  }

  void selectWeek(DateTime weekStart) {
    _selectedWeekStart = getMondayOfWeek(weekStart);
    final weekDays = currentWeekDays;
    if (weekDays.isNotEmpty) {
      // Если выбранный день есть на этой неделе — сохраняем его
      final match = weekDays.where((d) => d.dayOfWeek == _selectedDay).firstOrNull;
      if (match != null) {
        _selectedDay = match.dayOfWeek;
        _selectedDateStr = match.date;
      } else {
        _selectedDay = weekDays.first.dayOfWeek;
        _selectedDateStr = weekDays.first.date;
      }
    }
    notifyListeners();
  }

  void nextWeek() {
    selectWeek(_selectedWeekStart.add(const Duration(days: 7)));
  }

  void previousWeek() {
    selectWeek(_selectedWeekStart.subtract(const Duration(days: 7)));
  }

  void goToToday() {
    final now = DateTime.now();
    _selectedWeekStart = getMondayOfWeek(now);
    _updateSelectedDayForCurrentSchedule();
    notifyListeners();
  }

  /// Полные 7 дней выбранной недели (Пн-Вс, включая Субботу!)
  List<DaySchedule> get currentWeekDays {
    if (_schedule == null || _schedule!.days.isEmpty) {
      return [];
    }

    final monday = normalizeDate(_selectedWeekStart);
    final sunday =
        monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return _schedule!.days.where((day) {
      try {
        final parts = day.date.split('.');
        if (parts.length == 3) {
          final dayDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return !dayDate.isBefore(monday) && !dayDate.isAfter(sunday);
        }
      } catch (_) {
        return false;
      }
      return false;
    }).toList();
  }

  void _updateSelectedDayForCurrentSchedule() {
    if (_schedule == null || _schedule!.days.isEmpty) return;

    final now = DateTime.now();
    final todayStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final todayName = _getDayName(now.weekday);

    final weekDays = currentWeekDays;
    if (weekDays.isEmpty) {
      _selectedDay = todayName;
      _selectedDateStr = todayStr;
      return;
    }

    // Ищем сегодняшний день на текущей неделе
    final todayInWeek = weekDays.where((d) => d.date == todayStr).firstOrNull;
    if (todayInWeek != null) {
      _selectedDay = todayInWeek.dayOfWeek;
      _selectedDateStr = todayInWeek.date;
      return;
    }

    // Если сегодня выходной или пары нет, выбираем совпадающий день недели или первый доступный
    final matchDay =
        weekDays.where((d) => d.dayOfWeek == todayName).firstOrNull;
    if (matchDay != null) {
      _selectedDay = matchDay.dayOfWeek;
      _selectedDateStr = matchDay.date;
    } else {
      _selectedDay = weekDays.first.dayOfWeek;
      _selectedDateStr = weekDays.first.date;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return 'Понедельник';
    }
  }

  Future<bool> hasSelectedGroup() async {
    final groupId = await _repository.getSavedGroupId();
    return groupId != null;
  }

  Future<void> initializeApp() async {
    if (_initialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final groupId = await _repository.getSavedGroupId();
      final groupName = await _repository.getSavedGroupName();

      if (groupId != null && groupName != null) {
        _currentGroupId = groupId;
        _currentGroupName = groupName;

        // 1. Мгновенно загружаем кэшированное расписание для быстрого старта (0 мс ожидания)
        _schedule = await _repository.getSchedule(groupId, forceUpdate: false);
        _lastUpdated = await _repository.getLastUpdated();
        _updateSelectedDayForCurrentSchedule();

        _initialized = true;
        _isLoading = false;
        notifyListeners();

        // 2. В фоне обновляем расписание с сервера, если кэш устарел
        _backgroundSync(groupId, groupName);
      } else {
        _initialized = true;
        _isLoading = false;
        notifyListeners();
      }

      await loadGroups();
    } catch (_) {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _backgroundSync(int groupId, String groupName) async {
    try {
      final oldSchedule = _schedule;
      final freshSchedule =
          await _repository.getSchedule(groupId, forceUpdate: false);

      if (freshSchedule != oldSchedule) {
        _schedule = freshSchedule;
        _lastUpdated = await _repository.getLastUpdated() ?? DateTime.now();
        await _checkScheduleChanges(oldSchedule, _schedule);
        notifyListeners();
      }
    } catch (_) {
      // Background sync silently fails if offline
    }
  }

  Future<void> _checkScheduleChanges(
      FullSchedule? oldSchedule, FullSchedule? newSchedule) async {
    if (oldSchedule == null || newSchedule == null) return;

    bool hasChanges = false;
    String changeMessage = '';

    if (oldSchedule.days.length != newSchedule.days.length) {
      hasChanges = true;
      changeMessage = 'Изменилось расписание занятий';
    } else {
      for (var newDay in newSchedule.days) {
        final oldDay = oldSchedule.days.where((d) => d.date == newDay.date).firstOrNull;

        if (oldDay == null) {
          hasChanges = true;
          changeMessage = 'Обновлено расписание на ${newDay.dayOfWeek}';
          break;
        }

        if (oldDay.lessons.length != newDay.lessons.length) {
          hasChanges = true;
          changeMessage = 'Изменилось количество пар на ${newDay.dayOfWeek}';
          break;
        }

        for (var newLesson in newDay.lessons) {
          final oldLesson = oldDay.lessons
              .where((l) => l.time == newLesson.time && l.disc == newLesson.disc)
              .firstOrNull;

          if (oldLesson == null ||
              oldLesson.aud != newLesson.aud ||
              oldLesson.prepod != newLesson.prepod ||
              oldLesson.vidZan != newLesson.vidZan) {
            hasChanges = true;
            changeMessage = 'Изменения в расписании на ${newDay.dayOfWeek}';
            break;
          }
        }

        if (hasChanges) break;
      }
    }

    if (hasChanges) {
      await NotificationService.scheduleScheduleNotification(
        'Изменение в расписании',
        changeMessage,
        DateTime.now().add(const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _scheduleUpcomingLessonsNotifications() async {
    if (_schedule == null) return;

    try {
      await NotificationService.cancelAllLessonNotifications();
    } catch (_) {}

    final now = DateTime.now();
    final period = await NotificationService.getNotificationPeriod();

    try {
      for (var day in _schedule!.days) {
        final parts = day.date.split('.');
        if (parts.length == 3) {
          final dayDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );

          if (dayDate.isAfter(now.subtract(const Duration(days: 1))) &&
              dayDate.isBefore(now.add(Duration(days: period + 1)))) {
            for (var lesson in day.lessons) {
              final lessonTime = _parseLessonTime(lesson.time, dayDate);
              if (lessonTime != null && lessonTime.isAfter(now)) {
                final notificationTime =
                    lessonTime.subtract(const Duration(minutes: 15));
                if (notificationTime.isAfter(now)) {
                  final notificationId =
                      NotificationService.generateLessonNotificationId(
                    day.date,
                    lesson.time,
                  );

                  await NotificationService.scheduleLessonNotification(
                    'Скоро пара',
                    '${lesson.disc}\n${lesson.time}, ауд. ${lesson.aud}',
                    notificationTime,
                    notificationId: notificationId,
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  DateTime? _parseLessonTime(String timeStr, DateTime dayDate) {
    try {
      final parts = timeStr.split('-');
      if (parts.isNotEmpty) {
        final timeParts = parts[0].trim().split(':');
        if (timeParts.length == 2) {
          return DateTime(
            dayDate.year,
            dayDate.month,
            dayDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> resetApp() async {
    await NotificationService.cancelAllNotifications();
    await _repository.clearAllData();
    _schedule = null;
    _selectedDay = null;
    _selectedDateStr = null;
    _currentGroupId = null;
    _currentGroupName = null;
    _lastUpdated = null;
    _initialized = false;
    notifyListeners();
  }

  Future<String?> getCurrentGroupName() async {
    return _currentGroupName ?? await _repository.getSavedGroupName();
  }

  Future<int?> getSavedGroupId() async {
    return _currentGroupId ?? await _repository.getSavedGroupId();
  }

  Future<String?> getSavedGroupName() async {
    return _currentGroupName ?? await _repository.getSavedGroupName();
  }
}

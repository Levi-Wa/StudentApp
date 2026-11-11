import '../models/full_schedule.dart';
import '../repositories/schedule_repository.dart';
import 'notification_service.dart';

class ScheduleChangeItem {
  final String date;
  final String dayOfWeek;
  final String changeType; // 'added', 'removed', 'modified'
  final String description;

  ScheduleChangeItem({
    required this.date,
    required this.dayOfWeek,
    required this.changeType,
    required this.description,
  });
}

class ScheduleComparisonResult {
  final bool hasChanges;
  final List<ScheduleChangeItem> changes;
  final DateTime checkedAt;
  final String summary;

  ScheduleComparisonResult({
    required this.hasChanges,
    required this.changes,
    required this.checkedAt,
    required this.summary,
  });
}

class ScheduleComparisonService {
  static final ScheduleComparisonService _instance =
      ScheduleComparisonService._internal();
  factory ScheduleComparisonService() => _instance;
  ScheduleComparisonService._internal();

  final ScheduleRepository _repository = ScheduleRepository();

  /// Compares local saved schedule with latest schedule from server
  Future<ScheduleComparisonResult> compareScheduleWithServer({
    int? targetGroupId,
  }) async {
    final groupId = targetGroupId ?? await _repository.getSavedGroupId();
    if (groupId == null) {
      return ScheduleComparisonResult(
        hasChanges: false,
        changes: [],
        checkedAt: DateTime.now(),
        summary: 'Учебная группа не выбрана',
      );
    }

    // 1. Get cached schedule
    final cachedSchedule =
        await _repository.getSchedule(groupId, forceUpdate: false);

    // 2. Fetch fresh schedule from server
    FullSchedule? serverSchedule;
    try {
      serverSchedule =
          await _repository.getSchedule(groupId, forceUpdate: true);
    } catch (e) {
      return ScheduleComparisonResult(
        hasChanges: false,
        changes: [],
        checkedAt: DateTime.now(),
        summary: 'Не удалось загрузить данные с сервера для проверки: $e',
      );
    }

    final changes = _findDifferences(cachedSchedule, serverSchedule);

    final result = ScheduleComparisonResult(
      hasChanges: changes.isNotEmpty,
      changes: changes,
      checkedAt: DateTime.now(),
      summary: changes.isEmpty
          ? 'Расписание актуально. Изменений с сервером не обнаружено.'
          : 'Обнаружено изменений: ${changes.length}',
    );

    // If changes were found, trigger local notification
    if (result.hasChanges) {
      final preview =
          changes.take(2).map((c) => '• ${c.description}').join('\n');
      await NotificationService.scheduleScheduleNotification(
        'Изменения в расписании (проверка в 17:00)',
        preview,
        DateTime.now().add(const Duration(seconds: 1)),
      );
    }

    return result;
  }

  List<ScheduleChangeItem> _findDifferences(
    FullSchedule oldSchedule,
    FullSchedule newSchedule,
  ) {
    final List<ScheduleChangeItem> differences = [];
    final now = DateTime.now();

    // Check days starting from today and ahead
    for (final newDay in newSchedule.days) {
      DateTime? dayDate;
      try {
        final p = newDay.date.split('.');
        if (p.length == 3) {
          dayDate = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      } catch (_) {}

      // Only check today and upcoming days (skip past)
      if (dayDate != null &&
          dayDate.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }

      final oldDay =
          oldSchedule.days.where((d) => d.date == newDay.date).firstOrNull;

      if (oldDay == null) {
        if (newDay.lessons.isNotEmpty) {
          differences.add(
            ScheduleChangeItem(
              date: newDay.date,
              dayOfWeek: newDay.dayOfWeek,
              changeType: 'added',
              description:
                  '${newDay.date} (${newDay.dayOfWeek}): Добавлен новый учебный день (${newDay.lessons.length} пар)',
            ),
          );
        }
        continue;
      }

      // Check lessons
      for (final newLesson in newDay.lessons) {
        final oldLesson = oldDay.lessons
            .where((l) => l.time == newLesson.time && l.disc == newLesson.disc)
            .firstOrNull;

        if (oldLesson == null) {
          differences.add(
            ScheduleChangeItem(
              date: newDay.date,
              dayOfWeek: newDay.dayOfWeek,
              changeType: 'added',
              description:
                  '${newDay.date} (${newDay.dayOfWeek}) в ${newLesson.time}: Добавлена пара "${newLesson.disc}" (ауд. ${newLesson.aud.isEmpty ? '—' : newLesson.aud})',
            ),
          );
        } else {
          // Check modifications
          if (oldLesson.aud != newLesson.aud && newLesson.aud.isNotEmpty) {
            differences.add(
              ScheduleChangeItem(
                date: newDay.date,
                dayOfWeek: newDay.dayOfWeek,
                changeType: 'modified',
                description:
                    '${newDay.date} в ${newLesson.time} "${newLesson.disc}": перенос в ауд. ${newLesson.aud} (была ${oldLesson.aud.isEmpty ? '—' : oldLesson.aud})',
              ),
            );
          }
          if (oldLesson.prepod != newLesson.prepod &&
              newLesson.prepod.isNotEmpty) {
            differences.add(
              ScheduleChangeItem(
                date: newDay.date,
                dayOfWeek: newDay.dayOfWeek,
                changeType: 'modified',
                description:
                    '${newDay.date} в ${newLesson.time} "${newLesson.disc}": преподаватель заменён на ${newLesson.prepod}',
              ),
            );
          }
        }
      }

      // Check removed lessons
      for (final oldLesson in oldDay.lessons) {
        final stillExists = newDay.lessons
            .any((l) => l.time == oldLesson.time && l.disc == oldLesson.disc);
        if (!stillExists) {
          differences.add(
            ScheduleChangeItem(
              date: newDay.date,
              dayOfWeek: newDay.dayOfWeek,
              changeType: 'removed',
              description:
                  '${newDay.date} (${newDay.dayOfWeek}) в ${oldLesson.time}: Отменена пара "${oldLesson.disc}"',
            ),
          );
        }
      }
    }

    return differences;
  }
}

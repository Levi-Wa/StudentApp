import 'package:hive/hive.dart';
import 'day_schedule.dart';

part 'full_schedule.g.dart';

@HiveType(typeId: 2)
class FullSchedule extends HiveObject {
  @HiveField(0)
  final String group;

  @HiveField(1)
  final List<DaySchedule> days;

  @HiveField(2)
  final DateTime lastUpdated;

  FullSchedule({
    required this.group,
    required this.days,
    required this.lastUpdated,
  });

  factory FullSchedule.fromJson(Map<String, dynamic> json) {
    print('FullSchedule: Начинаю парсинг JSON...');
    final List<DaySchedule> allDays = [];
    
    if (json['Month'] != null) {
      final months = json['Month'] as List;
      print('FullSchedule: Найдено месяцев: ${months.length}');
      for (var month in months) {
        if (month['Sched'] != null) {
          final schedules = month['Sched'] as List;
          print('FullSchedule: В месяце найдено дней: ${schedules.length}');
          for (var sched in schedules) {
            try {
              final day = DaySchedule.fromJson(sched);
              allDays.add(day);
              print('  + Добавлен день: ${day.dayOfWeek} (${day.date}) - ${day.lessons.length} занятий');
            } catch (e) {
              print('  - Ошибка парсинга дня: $e');
            }
          }
        } else {
          print('FullSchedule: В месяце нет расписания');
          }
        }
    } else {
      print('FullSchedule: В JSON нет поля Month');
    }
    
    final schedule = FullSchedule(
      group: json['group'] ?? '',
      days: allDays,
      lastUpdated: DateTime.now(),
    );

    print('FullSchedule: Парсинг завершен. Группа: ${schedule.group}, дней: ${schedule.days.length}');
    return schedule;
  }
}

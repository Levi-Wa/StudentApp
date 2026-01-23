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
    final List<DaySchedule> allDays = [];

    if (json['Month'] != null) {
      final months = json['Month'] as List;
      for (var month in months) {
        if (month['Sched'] != null) {
          final schedules = month['Sched'] as List;
          for (var sched in schedules) {
            try {
              final day = DaySchedule.fromJson(sched);
              allDays.add(day);
            } catch (e) {
              // ignore parsing errors
            }
          }
        }
      }
    }

    final schedule = FullSchedule(
      group: json['group'] ?? '',
      days: allDays,
      lastUpdated: DateTime.now(),
    );

    return schedule;
  }
}

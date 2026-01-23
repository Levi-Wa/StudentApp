import 'package:hive/hive.dart';
import 'lesson.dart';

part 'day_schedule.g.dart';

@HiveType(typeId: 1)
class DaySchedule extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final String dayOfWeek;

  @HiveField(2)
  final List<Lesson> lessons;

  DaySchedule({
    required this.date,
    required this.dayOfWeek,
    required this.lessons,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final List<Lesson> lessons = [];
    final dayOfWeek = json['dayWeek'] ?? '';
    
    if (json['mainSchedule'] != null) {
      final mainSchedule = json['mainSchedule'] as List;
      for (var lesson in mainSchedule) {
        final lessonData = Map<String, dynamic>.from(lesson);
        lessonData['dayOfWeek'] = dayOfWeek;
        lessons.add(Lesson.fromJson(lessonData));
      }
    }
    
    return DaySchedule(
      date: json['datePair'] ?? '',
      dayOfWeek: dayOfWeek,
      lessons: lessons,
    );
  }
}

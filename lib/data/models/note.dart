import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 3)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String disc;

  @HiveField(2)
  String text;

  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  String endLessonTime;

  @HiveField(5)
  DateTime createdAt;

  Note({
    required this.id,
    required this.disc,
    required this.text,
    required this.endDate,
    required this.endLessonTime,
    required this.createdAt,
  });

  bool get isExpired {
    final now = DateTime.now();
    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      int.parse(endLessonTime.split(':')[0]),
      int.parse(endLessonTime.split(':')[1]),
    );
    return now.isAfter(endDateTime);
  }
}
import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 0)
class Lesson extends HiveObject {
  @HiveField(0)
  final String time;

  @HiveField(1)
  final String disc;

  @HiveField(2)
  final String prepod;

  @HiveField(3)
  final String aud;

  @HiveField(4)
  final String vidZan;

  @HiveField(5)
  final String dayOfWeek;

  Lesson({
    required this.time,
    required this.disc,
    required this.prepod,
    required this.aud,
    required this.vidZan,
    required this.dayOfWeek,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      time: json['TimeStart'] ?? '',
      disc: json['SubjName'] ?? '',
      prepod: json['FIO'] ?? '',
      aud: json['Aud'] ?? '',
      vidZan: json['LoadKindSN'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
    );
  }
}

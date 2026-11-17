import 'package:dio/dio.dart';
import '../models/classroom_occupancy.dart';
import '../models/full_schedule.dart';
import '../models/lesson.dart';

class RoomStatus {
  final Classroom classroom;
  final bool isBusy;
  final Lesson? lesson;

  RoomStatus({
    required this.classroom,
    required this.isBusy,
    this.lesson,
  });
}

class ClassroomService {
  static final ClassroomService _instance = ClassroomService._internal();
  factory ClassroomService() => _instance;
  ClassroomService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'StudentApp/1.0',
      },
    ),
  );

  ClassroomOccupancyData? _data;
  bool _isLoading = false;

  ClassroomOccupancyData? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _isLoading;

  /// Loads the classroom, building and pairs data
  Future<ClassroomOccupancyData> loadClassroomData({bool forceReload = false}) async {
    if (_data != null && !forceReload) {
      return _data!;
    }

    _isLoading = true;
    try {
      const url = 'https://api-1.ursei.su/schedule/GetBusyAudIniData';
      final response = await _dio.get(url);

      if (response.data != null && response.data is Map<String, dynamic>) {
        _data = ClassroomOccupancyData.fromJson(
          response.data as Map<String, dynamic>,
        );
        return _data!;
      } else {
        throw Exception('Неверный формат ответа от сервера');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Calculates room occupancy for a specific building, date and pair
  List<RoomStatus> getOccupancyForBuilding({
    required ClassroomBuilding building,
    required DateTime date,
    required ClassroomPair pair,
    FullSchedule? schedule,
  }) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    // Find lessons for this date
    final daySchedule =
        schedule?.days.where((d) => d.date == dateStr).firstOrNull;
    final dayLessons = daySchedule?.lessons ?? [];

    final List<RoomStatus> statuses = [];

    for (final room in building.auds) {
      Lesson? matchedLesson;

      for (final l in dayLessons) {
        final audClean = l.aud.toLowerCase().trim();
        final roomClean = room.audName.toLowerCase().trim();

        // Check if auditory matches (e.g. "606/ГК" contains "606", or exact match)
        final bool audMatches = audClean == roomClean ||
            audClean.startsWith('$roomClean/') ||
            audClean.contains('/$roomClean') ||
            (roomClean.length >= 3 && audClean.contains(roomClean));

        if (audMatches) {
          // Check if time/pair matches
          final lessonTime = l.time.trim();
          final pairStart = pair.timeStart.trim();

          final bool timeMatches = lessonTime.startsWith(pairStart) ||
              lessonTime.contains(pairStart) ||
              _isTimeOverlap(lessonTime, pair.timeStart, pair.timeEnd);

          if (timeMatches) {
            matchedLesson = l;
            break;
          }
        }
      }

      statuses.add(
        RoomStatus(
          classroom: room,
          isBusy: matchedLesson != null,
          lesson: matchedLesson,
        ),
      );
    }

    return statuses;
  }

  bool _isTimeOverlap(String lessonTime, String pairStart, String pairEnd) {
    try {
      final parts = lessonTime.split('-');
      if (parts.length != 2) return false;
      final lStart = parts[0].trim();
      final lEnd = parts[1].trim();

      // Simple string comparison for HH:mm
      return lStart.compareTo(pairEnd) < 0 && lEnd.compareTo(pairStart) > 0;
    } catch (_) {
      return false;
    }
  }
}

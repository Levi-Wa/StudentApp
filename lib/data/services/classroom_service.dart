import 'package:dio/dio.dart';
import '../models/classroom_occupancy.dart';
import '../models/full_schedule.dart';
import '../models/lesson.dart';

class RoomStatus {
  final Classroom classroom;
  final bool isBusy;
  final Lesson? lesson;

  // Institute-wide details directly from GetBusyAudsOnDatePair
  final String? subjName;
  final String? teacherFio;
  final String? groupName;
  final String? loadKind;
  final String? timeStart;

  RoomStatus({
    required this.classroom,
    required this.isBusy,
    this.lesson,
    this.subjName,
    this.teacherFio,
    this.groupName,
    this.loadKind,
    this.timeStart,
  });

  String? get displaySubject => subjName ?? lesson?.disc;

  String? get displayTeacher => teacherFio ?? lesson?.prepod;

  String? get displayGroup => groupName ?? lesson?.aud;

  String? get displayType => loadKind ?? lesson?.vidZan;

  String? get displayTime => timeStart ?? lesson?.time;
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
  final Map<String, List<RoomStatus>> _globalOccupancyCache = {};

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

  /// Fetches institute-wide real occupancy from official API (GetBusyAudsOnDatePair)
  Future<List<RoomStatus>> fetchGlobalOccupancy({
    required ClassroomBuilding building,
    required DateTime date,
    required ClassroomPair pair,
    FullSchedule? fallbackSchedule,
    bool forceReload = false,
  }) async {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final cacheKey = '$dateStr-${pair.pairId}-${building.buildingName}';

    if (!forceReload && _globalOccupancyCache.containsKey(cacheKey)) {
      return _globalOccupancyCache[cacheKey]!;
    }

    try {
      final url =
          'https://api-1.ursei.su/schedule/GetBusyAudsOnDatePair?date=$dateStr&pairid=${pair.pairId}';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['Buildings'] is List) {
          final buildings = data['Buildings'] as List;

          final bData = buildings.firstWhere(
            (b) =>
                (b['BuildingName']?.toString().trim() ?? '').toLowerCase() ==
                building.buildingName.toLowerCase(),
            orElse: () => null,
          );

          if (bData != null && bData['Auds'] is List) {
            final auds = bData['Auds'] as List;
            final List<RoomStatus> statuses = [];

            for (final room in building.auds) {
              final match = auds.firstWhere(
                (a) {
                  final aAudId = a['AudID'];
                  if (aAudId != null && aAudId == room.audId) return true;
                  final aName =
                      (a['Aud']?.toString() ?? '').trim().toLowerCase();
                  final rName = room.audName.trim().toLowerCase();
                  return aName.isNotEmpty &&
                      (aName == rName || aName.contains(rName));
                },
                orElse: () => null,
              );

              if (match != null && match['TimeStart'] != null) {
                statuses.add(
                  RoomStatus(
                    classroom: room,
                    isBusy: true,
                    subjName: match['SubjName']?.toString() ??
                        match['SubjSN']?.toString(),
                    teacherFio: match['EmpFIO']?.toString(),
                    groupName: match['GSName']?.toString(),
                    loadKind: match['LoadKindSN']?.toString(),
                    timeStart: match['TimeStart']?.toString(),
                  ),
                );
              } else {
                statuses.add(
                  RoomStatus(
                    classroom: room,
                    isBusy: false,
                  ),
                );
              }
            }

            _globalOccupancyCache[cacheKey] = statuses;
            return statuses;
          }
        }
      }
    } catch (_) {
      // Fallback below
    }

    // Fallback to local schedule if network failed or offline
    final local = getOccupancyForBuilding(
      building: building,
      date: date,
      pair: pair,
      schedule: fallbackSchedule,
    );
    return local;
  }

  /// Calculates room occupancy for a specific building, date and pair from local schedule
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

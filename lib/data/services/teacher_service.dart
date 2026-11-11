import 'package:dio/dio.dart';
import '../models/teacher.dart';

class TeacherService {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

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

  List<Department> _departments = [];
  List<Teacher> _teachers = [];
  bool _isLoaded = false;

  List<Department> get departments => _departments;
  List<Teacher> get teachers => _teachers;
  bool get isLoaded => _isLoaded;

  /// Loads initial teacher & department metadata
  Future<void> loadTeachersData({bool forceReload = false}) async {
    if (_isLoaded && !forceReload) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final url = 'https://api-1.ursei.su/schedule/GetTeachersIniData?d=$dateStr';

    try {
      final response = await _dio.get(url);
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['Departs'] is List) {
          _departments = (data['Departs'] as List)
              .map((d) => Department.fromJson(d as Map<String, dynamic>))
              .toList();
        }

        if (data['Teachers'] is List) {
          _teachers = (data['Teachers'] as List)
              .map((t) => Teacher.fromJson(t as Map<String, dynamic>))
              .toList();
        }

        _isLoaded = true;
      }
    } catch (e) {
      // If api-1 fails, try fallback without date parameter or throw
      try {
        const fallbackUrl = 'https://api-1.ursei.su/schedule/GetTeachersIniData';
        final response = await _dio.get(fallbackUrl);
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['Departs'] is List) {
            _departments = (data['Departs'] as List)
                .map((d) => Department.fromJson(d as Map<String, dynamic>))
                .toList();
          }
          if (data['Teachers'] is List) {
            _teachers = (data['Teachers'] as List)
                .map((t) => Teacher.fromJson(t as Map<String, dynamic>))
                .toList();
          }
          _isLoaded = true;
        }
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Finds a teacher by FIO (e.g. from a lesson card)
  Future<Teacher?> findTeacherByFio(String fio) async {
    if (!_isLoaded) {
      await loadTeachersData();
    }

    final cleanFio = fio.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (cleanFio.isEmpty) return null;

    // 1. Exact match
    for (final teacher in _teachers) {
      if (teacher.fio.toLowerCase().trim() == cleanFio) {
        return teacher;
      }
    }

    // 2. Contains match (e.g. "доц. Вихорев М.С.")
    for (final teacher in _teachers) {
      final tFio = teacher.fio.toLowerCase().trim();
      if (cleanFio.contains(tFio) || tFio.contains(cleanFio)) {
        return teacher;
      }
    }

    // 3. Surname match
    final surname = cleanFio.split(' ').first;
    if (surname.length > 3) {
      for (final teacher in _teachers) {
        if (teacher.fio.toLowerCase().startsWith(surname)) {
          return teacher;
        }
      }
    }

    return null;
  }

  /// Gets teachers belonging to a specific department
  List<Teacher> getTeachersByDepartment(int departId) {
    return _teachers.where((t) => t.departId == departId).toList();
  }

  /// Fetches schedule for a specific teacher for a date range
  Future<List<TeacherDaySchedule>> getTeacherSchedule({
    required int departId,
    required int empId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now().add(const Duration(days: 30));

    final dstart =
        '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}';
    final dend =
        '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';

    final url =
        'https://api-1.ursei.su/schedule/GetTeacherSched?departid=$departId&empid=$empId&dstart=$dstart&dend=$dend';

    try {
      final response = await _dio.get(url);
      if (response.data == null) return [];

      final data = response.data;
      final List<TeacherDaySchedule> result = [];

      if (data is Map<String, dynamic> && data['Month'] is List) {
        final months = data['Month'] as List;
        for (final m in months) {
          if (m is Map<String, dynamic> && m['Sched'] != null) {
            final schedObj = m['Sched'];

            // Sched can be Map<String, dynamic> (e.g. {"2026-11-02": {...}})
            if (schedObj is Map) {
              schedObj.forEach((key, dayValue) {
                if (dayValue is Map) {
                  final dayMap = Map<String, dynamic>.from(dayValue);
                  final datePair = dayMap['datePair']?.toString() ?? key.toString();
                  final dayWeek = dayMap['dayWeek']?.toString() ?? '';
                  final dayWeekShort = dayMap['dayWeekShort']?.toString() ?? '';

                  final List<TeacherLesson> lessons = [];
                  if (dayMap['mainSchedule'] is List) {
                    for (final l in dayMap['mainSchedule'] as List) {
                      if (l is Map) {
                        lessons.add(TeacherLesson.fromJson(Map<String, dynamic>.from(l)));
                      }
                    }
                  }

                  if (lessons.isNotEmpty) {
                    result.add(TeacherDaySchedule(
                      date: datePair,
                      dayOfWeek: dayWeek,
                      dayOfWeekShort: dayWeekShort,
                      lessons: lessons,
                    ));
                  }
                }
              });
            } else if (schedObj is List) {
              // Sched can be List (like in group schedules)
              for (final dayItem in schedObj) {
                if (dayItem is Map) {
                  final dayMap = Map<String, dynamic>.from(dayItem);
                  final datePair = dayMap['datePair']?.toString() ?? '';
                  final dayWeek = dayMap['dayWeek']?.toString() ?? '';
                  final dayWeekShort = dayMap['dayWeekShort']?.toString() ?? '';

                  final List<TeacherLesson> lessons = [];
                  if (dayMap['mainSchedule'] is List) {
                    for (final l in dayMap['mainSchedule'] as List) {
                      if (l is Map) {
                        lessons.add(TeacherLesson.fromJson(Map<String, dynamic>.from(l)));
                      }
                    }
                  }

                  if (lessons.isNotEmpty) {
                    result.add(TeacherDaySchedule(
                      date: datePair,
                      dayOfWeek: dayWeek,
                      dayOfWeekShort: dayWeekShort,
                      lessons: lessons,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      // Sort by date ascending
      result.sort((a, b) => a.date.compareTo(b.date));
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

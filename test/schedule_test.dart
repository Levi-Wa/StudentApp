import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/data/models/classroom_occupancy.dart';
import 'package:student_app/data/models/day_schedule.dart';
import 'package:student_app/data/models/full_schedule.dart';
import 'package:student_app/data/models/lesson.dart';
import 'package:student_app/data/providers/app_state.dart';
import 'package:student_app/data/services/classroom_service.dart';
import 'package:student_app/data/services/update_service.dart';
import 'package:student_app/theme/app_theme.dart';

void main() {
  group('AppState Date & Week logic tests', () {
    test('getMondayOfWeek correctly returns Monday at 00:00:00', () {
      // Wednesday 11 Nov 2026
      final wednesday = DateTime(2026, 11, 11, 16, 45, 30);
      final monday = AppState.getMondayOfWeek(wednesday);

      expect(monday.year, 2026);
      expect(monday.month, 11);
      expect(monday.day, 9);
      expect(monday.weekday, 1);
      expect(monday.hour, 0);
      expect(monday.minute, 0);
    });
 
    test('getMondayOfWeek on Sunday returns current week Monday', () {
      // Sunday 15 Nov 2026
      final sunday = DateTime(2026, 11, 15, 23, 59, 0);
      final monday = AppState.getMondayOfWeek(sunday);

      expect(monday.day, 9);
      expect(monday.weekday, 1);
    });

    test('currentWeekDays includes Monday through Saturday and Sunday', () {
      final appState = AppState();
      // Set week start to 09.11.2026 (Monday)
      appState.selectWeek(DateTime(2026, 11, 9));

      // Simulate schedule with lessons Monday, Friday and Saturday
      final fullSchedule = FullSchedule(
        group: 'БДД-101',
        lastUpdated: DateTime.now(),
        days: [
          DaySchedule(
            date: '09.11.2026',
            dayOfWeek: 'Понедельник',
            lessons: [],
          ),
          DaySchedule(
            date: '13.11.2026',
            dayOfWeek: 'Пятница',
            lessons: [],
          ),
          DaySchedule(
            date: '14.11.2026',
            dayOfWeek: 'Суббота',
            lessons: [],
          ),
          // Day in another week
          DaySchedule(
            date: '16.11.2026',
            dayOfWeek: 'Понедельник',
            lessons: [],
          ),
        ],
      );

      final weekDays = fullSchedule.days.where((day) {
        final monday = AppState.normalizeDate(appState.selectedWeekStart);
        final sunday = monday.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        final parts = day.date.split('.');
        final dayDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        return !dayDate.isBefore(monday) && !dayDate.isAfter(sunday);
      }).toList();

      expect(weekDays.length, 3);
      expect(weekDays.any((d) => d.dayOfWeek == 'Суббота'), isTrue);
      expect(weekDays.any((d) => d.date == '14.11.2026'), isTrue);
      expect(weekDays.any((d) => d.date == '16.11.2026'), isFalse);
    });

    test('FullSchedule json parsing handles URSEI API response structure', () {
      final json = {
        'Month': [
          {
            'MonthName': 'Ноябрь',
            'Sched': [
              {
                'datePair': '11.11.2026',
                'dayWeek': 'Среда',
                'mainSchedule': [
                  {
                    'TimeStart': '12:00',
                    'SubjName': 'Высшая математика',
                    'Aud': '301/ГК',
                    'FIO': 'Иванов И.И.',
                    'LoadKindSN': 'Лекция',
                  }
                ]
              }
            ]
          }
        ]
      };

      final schedule = FullSchedule.fromJson(json);
      expect(schedule.days.length, 1);
      expect(schedule.days.first.dayOfWeek, 'Среда');
      expect(schedule.days.first.lessons.length, 1);
      expect(schedule.days.first.lessons.first.disc, 'Высшая математика');
      expect(schedule.days.first.lessons.first.vidZan, 'Лекция');
      expect(schedule.days.first.lessons.first.aud, '301/ГК');
    });
  });

  group('UpdateService tests', () {
    test('compareVersions correctly identifies newer and older versions', () {
      expect(UpdateService.compareVersions('1.0.2', '1.0.1'), 1);
      expect(UpdateService.compareVersions('1.1.0', '1.0.9'), 1);
      expect(UpdateService.compareVersions('2.0.0', '1.9.9'), 1);
      expect(UpdateService.compareVersions('v1.0.2', '1.0.1'), 1);
      expect(UpdateService.compareVersions('1.0.4', '1.0.4'), 0);
      expect(UpdateService.compareVersions('1.0.1', '1.0.1'), 0);
      expect(UpdateService.compareVersions('1.0.0', '1.0.1'), -1);
    });

    test('extractVersion correctly parses release tags and names', () {
      expect(UpdateService.extractVersion('1.0.4'), '1.0.4');
      expect(UpdateService.extractVersion('v1.0.4'), '1.0.4');
      expect(UpdateService.extractVersion('Urse 1.0.4'), '1.0.4');
      expect(UpdateService.extractVersion('Urse'), '');
      expect(UpdateService.extractVersion('Release 2.0.1-beta'), '2.0.1');
    });
  });

  group('AppTheme styling tests', () {
    test('getLessonStyle returns vibrant colors matching image 1 reference', () {
      final (lectureBg, _, _, _) = AppTheme.getLessonStyle('Лекция', 0);
      expect(lectureBg, const Color(0xFF0284C7)); // Cyan

      final (practiceBg, _, _, _) = AppTheme.getLessonStyle('Практика', 1);
      expect(practiceBg, const Color(0xFFEA580C)); // Warm Coral / Orange

      final (labBg, _, _, _) = AppTheme.getLessonStyle('Лабораторная', 2);
      expect(labBg, const Color(0xFF7E22CE)); // Purple
    });
  });

  group('ClassroomOccupancy & Service tests', () {
    test('ClassroomOccupancyData parses JSON correctly', () {
      final json = {
        'Pairs': [
          {'Pair_ID': 17, 'PairNumb': 1, 'TimeStart': '08:30', 'TimeEnd': '10:05'},
          {'Pair_ID': 18, 'PairNumb': 2, 'TimeStart': '10:15', 'TimeEnd': '11:50'},
        ],
        'Buildings': [
          {
            'Building_ID': 1,
            'BuildingName': 'Главный корпус',
            'Auds': [
              {'Aud_ID': 3, 'AudName': '606', 'AudTypeName': 'Компьютерный класс', 'Volume': 20},
              {'Aud_ID': 96, 'AudName': '116', 'AudTypeName': 'Лекционная', 'Volume': 32},
            ],
          },
        ],
      };

      final data = ClassroomOccupancyData.fromJson(json);
      expect(data.pairs.length, 2);
      expect(data.pairs[0].pairNumb, 1);
      expect(data.pairs[0].timeStart, '08:30');
      expect(data.buildings.length, 1);
      expect(data.buildings[0].buildingName, 'Главный корпус');
      expect(data.buildings[0].auds.length, 2);
      expect(data.buildings[0].auds[0].audName, '606');
    });

    test('ClassroomService correctly marks occupied and free rooms', () {
      final service = ClassroomService();
      final building = ClassroomBuilding(
        buildingId: 1,
        buildingName: 'Главный корпус',
        auds: [
          Classroom(audId: 1, audName: '606', audTypeName: 'Компьютерный класс', volume: 20),
          Classroom(audId: 2, audName: '116', audTypeName: 'Лекционная', volume: 32),
        ],
      );

      final pair1 = ClassroomPair(pairId: 17, pairNumb: 1, timeStart: '08:30', timeEnd: '10:05');
      final pair2 = ClassroomPair(pairId: 18, pairNumb: 2, timeStart: '10:15', timeEnd: '11:50');

      // Schedule has 606 booked on 11.11.2026 during pair 1
      final schedule = FullSchedule(
        group: 'ИД-301кис',
        lastUpdated: DateTime.now(),
        days: [
          DaySchedule(
            date: '11.11.2026',
            dayOfWeek: 'Среда',
            lessons: [
              Lesson(
                time: '08:30 - 10:00',
                disc: 'Интернет-технологии',
                prepod: 'Корогод Н.А.',
                aud: '606/ГК',
                vidZan: 'Лабор',
                dayOfWeek: 'Среда',
              ),
            ],
          ),
        ],
      );

      final testDate = DateTime(2026, 11, 11);

      // On Pair 1: room 606 must be busy, room 116 must be free
      final statusesPair1 = service.getOccupancyForBuilding(
        building: building,
        date: testDate,
        pair: pair1,
        schedule: schedule,
      );

      expect(statusesPair1[0].classroom.audName, '606');
      expect(statusesPair1[0].isBusy, isTrue);
      expect(statusesPair1[0].lesson?.disc, 'Интернет-технологии');
      expect(statusesPair1[1].classroom.audName, '116');
      expect(statusesPair1[1].isBusy, isFalse);

      // On Pair 2: both rooms are free
      final statusesPair2 = service.getOccupancyForBuilding(
        building: building,
        date: testDate,
        pair: pair2,
        schedule: schedule,
      );

      expect(statusesPair2[0].isBusy, isFalse);
      expect(statusesPair2[1].isBusy, isFalse);
    });
  });
}

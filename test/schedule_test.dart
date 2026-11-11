import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/data/models/day_schedule.dart';
import 'package:student_app/data/models/full_schedule.dart';
import 'package:student_app/data/providers/app_state.dart';
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
      expect(UpdateService.compareVersions('1.0.1', '1.0.1'), 0);
      expect(UpdateService.compareVersions('1.0.0', '1.0.1'), -1);
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
}

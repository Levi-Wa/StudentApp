import 'package:flutter/material.dart';
import '../../../data/models/day_schedule.dart';

class DailyTimeline extends StatelessWidget {
  final DaySchedule daySchedule;

  const DailyTimeline({super.key, required this.daySchedule});

  @override
  Widget build(BuildContext context) {
    if (daySchedule.lessons.isEmpty) {
      return Center(
        child: Text(
          'Нет занятий в этот день',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16),
      itemCount: daySchedule.lessons.length,
      itemBuilder: (context, index) {
        final lesson = daySchedule.lessons[index];
        final times = lesson.time.split('-');
        final startTime = times.isNotEmpty ? times[0].trim() : '';
        final endTime = times.length > 1 ? times[1].trim() : _calculateEndTime(startTime);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Временная шкала слева
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  // Точка начала пары
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        startTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  // Линия между началом и концом
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey[300],
                    margin: EdgeInsets.only(left: 5),
                  ),
                  // Точка конца пары
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        endTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // Карточка с информацией о паре
            Expanded(
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.disc,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Аудитория: ${lesson.aud}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Преподаватель: ${lesson.prepod}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(lesson.vidZan).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lesson.vidZan,
                          style: TextStyle(
                            color: _getTypeColor(lesson.vidZan),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'лек':
        return Colors.blue;
      case 'пр':
        return Colors.green;
      case 'лаб':
      case 'лр':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _calculateEndTime(String startTime) {
    try {
      final parts = startTime.split(':');
      if (parts.length == 2) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);

        minutes += 90; // 90 минут на пару

        if (minutes >= 60) {
          hours += minutes ~/ 60;
          minutes = minutes % 60;
        }

        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // ignore
    }
    return '';
  }
}

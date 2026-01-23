import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/lesson.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/responsive_text.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final String? lessonDate;

  const LessonCard({super.key, required this.lesson, this.lessonDate});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'лек':
        return Color(0xCB0065FF);
      case 'пр':
        return Color(0xC50FFF00);
      case 'лаб':
      case 'лр':
        return Color(0xD5BCBCBC);
      default:
        return Color(0xD5BCBCBC);
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

  Color _getLessonStatusColor(String startTime, String endTime) {
    try {
      final now = DateTime.now();
      
      if (!_isToday()) {
        return Colors.grey;
      }
      
      final currentMinutes = now.hour * 60 + now.minute;
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      if (startParts.length == 2 && endParts.length == 2) {
        final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        
        if (currentMinutes < startMinutes) {
          return Colors.blue;
        } else if (currentMinutes >= endMinutes) {
          return Colors.grey;
        } else {
          return Colors.green;
        }
      }
    } catch (e) {
      // ignore
    }
    return Colors.grey;
  }
  
  bool _isToday() {
    final now = DateTime.now();
    
    if (lessonDate == null) return false;
    
    try {
      final parts = lessonDate!.split('.');
      if (parts.length == 3) {
        final lessonDateTime = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        return lessonDateTime.year == now.year && 
               lessonDateTime.month == now.month && 
               lessonDateTime.day == now.day;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final times = lesson.time.split('-');
    final startTime = times.isNotEmpty ? times[0].trim() : '';
    final endTime = times.length > 1 ? times[1].trim() : _calculateEndTime(startTime);
    


    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: double.infinity,
      ),
      margin: EdgeInsets.fromLTRB(5, 0, 5, 25),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 60,
              maxWidth: 80,
            ),
            child: SizedBox(
              width: (MediaQuery.of(context).size.width * 0.2).clamp(60.0, 80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  startTime,
                  style: GoogleFonts.interTight(
                      fontSize: ResponsiveText.subtitle(context),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                Text(
                  endTime,
                  style: GoogleFonts.inter(
                      fontSize: ResponsiveText.body(context),
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 5,
                    offset: Offset(2, 2),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    width: 6,
                    constraints: BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      color: _getLessonStatusColor(startTime, endTime),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              lesson.disc,
                              style: GoogleFonts.interTight(
                              fontSize: ResponsiveText.body(context),
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 4),
                          Text(
                            'Ауд: ${lesson.aud}',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                              lesson.prepod,
                              style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 4),
                          Text(
                            lesson.vidZan,
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context) * 0.9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

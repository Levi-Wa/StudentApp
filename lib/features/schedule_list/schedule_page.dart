import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:circular_menu/circular_menu.dart';
import '../../data/providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_text.dart';
import 'widgets/lesson_card.dart';
import 'widgets/horizontal_week_calendar_dialog.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  void initState() {
    super.initState();
    // Инициализация больше не нужна, так как расписание уже загружено в StartScreen
  }
  String _getDayAbbreviation(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'понедельник':
      case 'пн':
        return 'ПН';
      case 'вторник':
      case 'вт':
        return 'ВТ';
      case 'среда':
      case 'ср':
        return 'СР';
      case 'четверг':
      case 'чт':
        return 'ЧТ';
      case 'пятница':
      case 'пт':
        return 'ПТ';
      case 'суббота':
      case 'сб':
        return 'СБ';
      case 'воскресенье':
      case 'вс':
        return 'ВС';
      default:
        return dayName.length >= 2 ? dayName.substring(0, 2).toUpperCase() : dayName.toUpperCase();
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'января';
      case 2: return 'февраля';
      case 3: return 'марта';
      case 4: return 'апреля';
      case 5: return 'мая';
      case 6: return 'июня';
      case 7: return 'июля';
      case 8: return 'августа';
      case 9: return 'сентября';
      case 10: return 'октября';
      case 11: return 'ноября';
      case 12: return 'декабря';
      default: return 'января';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBackground,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Stack(
              children: [
                Positioned(
                  left: 16,
                  top: 40,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, size: 50, color: AppTheme.primaryText),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 45,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getMonthName(DateTime.now().month).substring(0, 3)} ',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${DateTime.now().year.toString().substring(2)}',
                            style: GoogleFonts.inter(
                              fontSize: ResponsiveText.small(context),
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${DateTime.now().day}',
                            style: GoogleFonts.oswald(
                              fontSize: ResponsiveText.title(context),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Расписание',
                        style: GoogleFonts.robotoCondensed(
                          fontSize: ResponsiveText.headline(context),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: SizedBox(
        width: 80,
        child: Drawer(
          backgroundColor: Color(0xFF14181B),
          child: Column(
            children: [
              SizedBox(height: 60),
              Expanded(
                child: Consumer<AppState>(
                  builder: (context, appState, child) {
                    final weekDays = appState.currentWeekDays;
                    if (weekDays.isEmpty) {
                      return Container();
                    }
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: weekDays.map<Widget>((day) {
                        final isSelected = day.dayOfWeek == appState.selectedDay;
                        return Container(
                          key: ValueKey(day.dayOfWeek),
                          margin: EdgeInsets.symmetric(vertical: 2),
                          child: SizedBox(
                            width: 65,
                            height: 65,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF282E35),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                appState.selectDay(day.dayOfWeek);
                              },
                              child: Text(
                                _getDayAbbreviation(day.dayOfWeek),
                                style: GoogleFonts.interTight(
                                    fontSize: ResponsiveText.body(context),
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.orange : Colors.white),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings, size: 45, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Consumer<AppState>(
          builder: (context, appState, child) {
        if (appState.isLoading) {
            return Center(child: CircularProgressIndicator());
        }
        if (appState.schedule == null) {
            return Center(child: Text('Нет данных'));
        }

          if (appState.schedule!.days.isEmpty) {
            return Center(child: Text('Нет расписания'));
          }

          final weekDays = appState.currentWeekDays;
          if (weekDays.isEmpty) {
            return Center(child: Text('Нет расписания на выбранную неделю'));
          }

          final selectedDay = weekDays.firstWhere(
            (day) => day.dayOfWeek == appState.selectedDay,
            orElse: () => weekDays.first,
          );

          if (selectedDay.lessons.isEmpty) {
            return Center(
              child: Text(
                'В этот день нет пар',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.primaryText.withOpacity(0.7),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(0, 15, 0, 25),
            itemCount: selectedDay.lessons.length,
            itemBuilder: (context, index) {
              return LessonCard(
                lesson: selectedDay.lessons[index],
                lessonDate: selectedDay.date,
              );
            },
          );
          },
        ),
      floatingActionButton: CircularMenu(
        alignment: Alignment.bottomRight,
        radius: 120,
        toggleButtonColor: Colors.black,
        toggleButtonIconColor: Colors.white,
        toggleButtonSize: 28,
        toggleButtonMargin: 16,
        backgroundWidget: Container(),
        items: [
          CircularMenuItem(
            icon: Icons.edit_note,
            color: Colors.black,
            iconColor: Colors.white,
            onTap: () => Navigator.pushNamed(context, '/notes'),
          ),
          CircularMenuItem(
            icon: Icons.date_range,
            color: Colors.black,
            iconColor: Colors.white,
            onTap: () => _showWeekSelector(),
          ),
        ],
      ),
    );
  }

  void _showWeekSelector() {
    showDialog(
      context: context,
      builder: (context) => HorizontalWeekCalendarDialog(),
    );
  }
}

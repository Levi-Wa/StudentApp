import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state.dart';

class WeekSelectorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return AlertDialog(
          title: Text('Выбор недели'),
          content: Container(
            height: 300,
            width: 300,
            child: CalendarDatePicker(
              initialDate: appState.selectedWeekStart,
              firstDate: DateTime.now().subtract(Duration(days: 365)),
              lastDate: DateTime.now().add(Duration(days: 365)),
              onDateChanged: (date) {
                final weekStart = date.subtract(Duration(days: date.weekday - 1));
                appState.selectWeek(weekStart);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }
}
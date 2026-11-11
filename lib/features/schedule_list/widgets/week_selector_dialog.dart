import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_state.dart';

class WeekSelectorDialog extends StatelessWidget {
  const WeekSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return AlertDialog(
          title: const Text('Выбор недели'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: CalendarDatePicker(
              initialDate: appState.selectedWeekStart,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (date) {
                final weekStart = AppState.getMondayOfWeek(date);
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DateFilter extends StatefulWidget {
  final Function(DateTime?) onDateSelected;

  const DateFilter({super.key, required this.onDateSelected});

  @override
  State<DateFilter> createState() => _DateFilterState();
}

class _DateFilterState extends State<DateFilter> {
  DateTime? selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    const itemWidth = 62.0;
    const todayIndex = 14; // Index of today in a 30-day window
    _scrollController.animateTo(
      todayIndex * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month - 1];
  }

  String _getDayAbbr(int weekday) {
    switch (weekday) {
      case 1:
        return 'пн';
      case 2:
        return 'вт';
      case 3:
        return 'ср';
      case 4:
        return 'чт';
      case 5:
        return 'пт';
      case 6:
        return 'сб';
      case 7:
        return 'вс';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // 30 days: 14 days before today and 15 days after
    final dates = List.generate(
      30,
      (index) => today.subtract(const Duration(days: 14)).add(Duration(days: index)),
    );

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: AppTheme.secondaryBackground,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: dates.length + 1, // +1 for "Все"
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = selectedDate == null;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDate = null;
                });
                widget.onDateSelected(null);
              },
              child: Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isAll
                      ? AppTheme.primaryAccent
                      : AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAll
                        ? AppTheme.primaryAccent
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 18,
                      color: isAll ? Colors.white : AppTheme.primaryText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Все',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAll ? Colors.white : AppTheme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final date = dates[index - 1];
          final isSelected = selectedDate?.day == date.day &&
              selectedDate?.month == date.month &&
              selectedDate?.year == date.year;
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = isSelected ? null : date;
              });
              widget.onDateSelected(selectedDate);
            },
            child: Container(
              width: 54,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryAccent
                    : (isToday
                        ? AppTheme.primaryAccent.withOpacity(0.12)
                        : AppTheme.surfaceBackground),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : (isToday
                          ? AppTheme.primaryAccent.withOpacity(0.5)
                          : AppTheme.dividerColor),
                  width: isSelected || isToday ? 1.4 : 0.8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayAbbr(date.weekday),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : (date.weekday >= 6
                              ? Colors.orange
                              : AppTheme.secondaryText),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(date.month),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

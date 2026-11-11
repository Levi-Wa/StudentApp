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
    const itemWidth = 56.0;
    const todayIndex = 14;
    _scrollController.animateTo(
      todayIndex * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getDaySingleLetter(int weekday) {
    switch (weekday) {
      case 1:
        return 'П';
      case 2:
        return 'В';
      case 3:
        return 'С';
      case 4:
        return 'Ч';
      case 5:
        return 'П';
      case 6:
        return 'С';
      case 7:
        return 'В';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
      30,
      (index) =>
          today.subtract(const Duration(days: 14)).add(Duration(days: index)),
    );

    final bg = AppTheme.secondaryBg(context);
    final text = AppTheme.text(context);
    final subtext = AppTheme.subtext(context);
    final surface = AppTheme.surface(context);
    final divider = AppTheme.divider(context);

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: bg,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: dates.length + 1,
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
                width: 52,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isAll ? AppTheme.dockActiveAmber : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAll ? AppTheme.dockActiveAmber : divider,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 16,
                      color: isAll ? Colors.black : text,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Все',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAll ? Colors.black : text,
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
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.dockActiveAmber
                    : (isToday
                        ? AppTheme.dockActiveAmber.withValues(alpha: 0.12)
                        : surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.dockActiveAmber
                      : (isToday
                          ? AppTheme.dockActiveAmber.withValues(alpha: 0.5)
                          : divider),
                  width: isSelected || isToday ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDaySingleLetter(date.weekday),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.8)
                          : (date.weekday >= 6
                              ? Colors.orange
                              : subtext),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.black : text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Image 1 bottom dot for selected day
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black
                          : (isToday
                              ? AppTheme.dockActiveAmber
                              : Colors.transparent),
                      shape: BoxShape.circle,
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/responsive_text.dart';

class DateFilter extends StatefulWidget {
  final Function(DateTime?) onDateSelected;

  const DateFilter({Key? key, required this.onDateSelected}) : super(key: key);

  @override
  _DateFilterState createState() => _DateFilterState();
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

  void _scrollToToday() {
    const itemWidth = 68.0; // 60 + 8 margin
    const todayIndex = 30; // Сегодня в середине списка
    _scrollController.animateTo(
      todayIndex * itemWidth,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(60, (index) => today.subtract(Duration(days: 30)).add(Duration(days: index)));

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selectedDate?.day == date.day &&
                           selectedDate?.month == date.month &&
                           selectedDate?.year == date.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = isSelected ? null : date;
              });
              widget.onDateSelected(selectedDate);
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.black 
                  : (date.weekday == 6 || date.weekday == 7) 
                    ? Colors.yellow 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.subtitle(context),
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.yellow : Colors.black,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(date.month),
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveText.small(context),
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.yellow : Colors.black,
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

  String _getMonthAbbr(int month) {
    switch (month) {
      case 1: return 'янв';
      case 2: return 'фев';
      case 3: return 'мар';
      case 4: return 'апр';
      case 5: return 'май';
      case 6: return 'июн';
      case 7: return 'июл';
      case 8: return 'авг';
      case 9: return 'сен';
      case 10: return 'окт';
      case 11: return 'ноя';
      case 12: return 'дек';
      default: return 'янв';
    }
  }
}
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class MoodCalendar extends StatefulWidget {
  final List<MoodEntry> logs;
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;

  const MoodCalendar({
    super.key,
    required this.logs,
    required this.onDateSelected,
    required this.selectedDate,
  });

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) {
    const names = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedDate.year,
      _focusedDate.month,
    );
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final offset = firstDayOfMonth.weekday - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month - 1,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _monthName(_focusedDate.month).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Text(
                    "${_focusedDate.year}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month + 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekdays
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => SizedBox(
                    width: 35,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();

              final day = index - offset + 1;
              final date = DateTime(_focusedDate.year, _focusedDate.month, day);
              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              MoodEntry? log;
              try {
                log = widget.logs.firstWhere(
                  (l) => _isSameDay(l.timestamp, date),
                );
              } catch (_) {}

              Color bgColor = log != null
                  ? log.color
                  : (isSelected
                        ? Colors.deepPurple
                        : (isToday
                              ? Colors.deepPurple.withValues(alpha: 0.1)
                              : Colors.transparent));
              Color textColor = (log != null || isSelected)
                  ? Colors.white
                  : Colors.black87;

              Border? border;
              if (isSelected) {
                border = Border.all(
                  color: log != null ? Colors.white70 : Colors.transparent,
                  width: 2,
                );
              } else if (isToday && log == null) {
                border = Border.all(color: Colors.deepPurple, width: 1);
              }

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: border,
                    boxShadow: log != null
                        ? [
                            BoxShadow(
                              color: log.color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: (isSelected || isToday || log != null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

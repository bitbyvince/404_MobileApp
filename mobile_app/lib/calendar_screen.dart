import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final bool tasksCompleted;
  final VoidCallback onTasksCompleted;

  const CalendarScreen({
    super.key,
    required this.tasksCompleted,
    required this.onTasksCompleted,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _displayDate = DateTime.now();
  }

  List<DateTime> _getDaysInMonth(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0);
    final daysInMonth = last.day;
    final firstDayOfWeek = first.weekday;

    List<DateTime> days = [];

    // Add previous month's days
    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      days.add(DateTime(date.year, date.month, 1 - i));
    }

    // Add current month's days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(date.year, date.month, i));
    }

    // Add next month's days
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(date.year, date.month + 1, i));
    }

    return days;
  }

  void _previousMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month + 1);
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _displayDate = DateTime(_displayDate.year, month);
    });
  }

  void _selectYear(int year) {
    setState(() {
      _displayDate = DateTime(year, _displayDate.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_displayDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  const Text(
                    'Medication',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Calendar Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Month/Year Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _previousMonth,
                          child: const Icon(
                            Icons.chevron_left,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            _buildDropdown(
                              value: _getMonthName(_displayDate.month),
                              onChanged: (month) {
                                _selectMonth(month);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDropdown(
                              value: _displayDate.year.toString(),
                              onChanged: (year) {
                                _selectYear(int.parse(year));
                              },
                              isYear: true,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _nextMonth,
                          child: const Icon(
                            Icons.chevron_right,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Days of week header
                    Row(
                      children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Calendar Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final isCurrentMonth =
                            day.month == _displayDate.month;
                        final isSelected =
                            day.day == _selectedDate.day &&
                            day.month == _selectedDate.month &&
                            day.year == _selectedDate.year;
                        final isToday =
                            day.day == DateTime.now().day &&
                            day.month == DateTime.now().month &&
                            day.year == DateTime.now().year;

                        return GestureDetector(
                          onTap: () {
                            if (isCurrentMonth) {
                              setState(() {
                                _selectedDate = day;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black
                                  : isToday
                                      ? Colors.grey[800]
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected || isToday
                                      ? Colors.white
                                      : isCurrentMonth
                                          ? Colors.black
                                          : Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.tasksCompleted
                      ? null
                      : () {
                          widget.onTasksCompleted();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Dose submitted for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.tasksCompleted
                        ? Colors.grey[400]
                        : const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    widget.tasksCompleted ? '✓ Dose Submitted' : "Submit Today's Dose",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Function(dynamic) onChanged,
    bool isYear = false,
  }) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final years = List.generate(10, (i) => (2020 + i).toString());

    return GestureDetector(
      onTap: () {
        _showDropdownMenu(
          value: value,
          items: isYear ? years : months,
          onSelected: onChanged,
          isYear: isYear,
        );
      },
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  void _showDropdownMenu({
    required String value,
    required List<String> items,
    required Function(String) onSelected,
    required bool isYear,
  }) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: items
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
    ).then((selectedValue) {
      if (selectedValue != null) {
        onSelected(selectedValue);
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

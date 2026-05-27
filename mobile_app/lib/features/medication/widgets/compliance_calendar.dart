import 'package:flutter/material.dart';

class ComplianceCalendar extends StatefulWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final String Function(DateTime date) getDayStatus;
  final void Function(DateTime date) onDateTap;
  final void Function(DateTime month) onMonthChanged;

  const ComplianceCalendar({
    super.key,
    required this.focusedMonth,
    this.selectedDate,
    required this.getDayStatus,
    required this.onDateTap,
    required this.onMonthChanged,
  });

  @override
  State<ComplianceCalendar> createState() => _ComplianceCalendarState();
}

class _ComplianceCalendarState extends State<ComplianceCalendar> {
  static const _weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<DateTime?> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startPadding = firstDay.weekday % 7;
    final days = <DateTime?>[];
    for (int i = 0; i < startPadding; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(widget.focusedMonth);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── MONTH HEADER ─────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  final prev = DateTime(
                    widget.focusedMonth.year,
                    widget.focusedMonth.month - 1,
                  );
                  widget.onMonthChanged(prev);
                },
                iconSize: 22,
                color: const Color(0xFF2D3748),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.focusedMonth.month,
                    alignment: Alignment.center,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_months[i]),
                      ),
                    ),
                    onChanged: (month) {
                      if (month == null) return;
                      widget.onMonthChanged(
                        DateTime(widget.focusedMonth.year, month),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  final next = DateTime(
                    widget.focusedMonth.year,
                    widget.focusedMonth.month + 1,
                  );
                  widget.onMonthChanged(next);
                },
                iconSize: 22,
                color: const Color(0xFF2D3748),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── WEEKDAY HEADERS ──────────────────────────────
          Row(
            children: _weekdays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── DAY GRID ─────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox.shrink();

              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected =
                  widget.selectedDate != null &&
                  date.year == widget.selectedDate!.year &&
                  date.month == widget.selectedDate!.month &&
                  date.day == widget.selectedDate!.day;
              final isFuture = date.isAfter(today);
              final status = isFuture ? 'future' : widget.getDayStatus(date);

              return _CalendarDay(
                date: date,
                status: status,
                isToday: isToday,
                isSelected: isSelected,
                isFuture: isFuture,
                onTap: isFuture ? null : () => widget.onDateTap(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final String status;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback? onTap;

  const _CalendarDay({
    required this.date,
    required this.status,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    this.onTap,
  });

  Color get _bgColor {
    if (isSelected) return const Color(0xFF1A73E8);
    switch (status) {
      case 'taken':
        return const Color(0xFF34A853);
      case 'partial':
        return const Color(0xFFFFA000);
      case 'missed':
        return const Color(0xFFE53935);
      default:
        return Colors.transparent;
    }
  }

  Widget get _content {
    if (isSelected) {
      return Text(
        '${date.day}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }
    switch (status) {
      case 'taken':
        return const Icon(Icons.check_rounded, color: Colors.white, size: 16);
      case 'missed':
        return const Icon(Icons.close_rounded, color: Colors.white, size: 16);
      case 'partial':
        return Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      case 'future':
        return Text(
          '${date.day}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
        );
      default:
        return Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday ? const Color(0xFF1A73E8) : const Color(0xFF2D3748),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          shape: BoxShape.circle,
          border: isToday && status == 'none'
              ? Border.all(color: const Color(0xFF1A73E8), width: 1.5)
              : null,
        ),
        child: Center(child: _content),
      ),
    );
  }
}

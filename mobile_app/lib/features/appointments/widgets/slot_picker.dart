import 'package:flutter/material.dart';

class SlotPicker extends StatelessWidget {
  final DateTime selectedDate;
  final String? selectedTime;
  final List<DateTime> availableSlots;
  final bool isLoading;
  final void Function(DateTime date) onDateChanged;
  final void Function(String time) onTimeSelected;

  const SlotPicker({
    super.key,
    required this.selectedDate,
    this.selectedTime,
    required this.availableSlots,
    required this.isLoading,
    required this.onDateChanged,
    required this.onTimeSelected,
  });

  List<DateTime> get _next14Days =>
      List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));

  String _formatDay(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── DATE ROW ─────────────────────────────────────
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _next14Days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = _next14Days[index];
              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return GestureDetector(
                onTap: () => onDateChanged(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A73E8)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDay(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── TIME SLOTS ───────────────────────────────────
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1A73E8),
              ),
            ),
          )
        else if (availableSlots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No available slots for this date.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSlots.map((slot) {
              final timeStr = _formatTime(slot);
              final isSelected = selectedTime == timeStr;
              return GestureDetector(
                onTap: () => onTimeSelected(timeStr),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A73E8)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2D3748),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/models/medication_log_model.dart';
import '../widgets/compliance_legend.dart';

class ComplianceCalendarScreen extends StatefulWidget {
  const ComplianceCalendarScreen({super.key});

  @override
  State<ComplianceCalendarScreen> createState() =>
      _ComplianceCalendarScreenState();
}

class _ComplianceCalendarScreenState extends State<ComplianceCalendarScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);
  static const _red = Color(0xFFE53935);
  static const _amber = Color(0xFFFFA000);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, MedicationLogModel> _logMap = {};
  MedicationLogModel? _selectedLog;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final result = await MedicationRepository.instance.getHistory(
        page: 1,
        limit: 60,
      );
      final map = <String, MedicationLogModel>{};
      for (final log in result.logs) {
        map[_key(log.logDate)] = log;
      }
      setState(() => _logMap = map);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color? _dayColor(DateTime day) {
    final log = _logMap[_key(day)];
    if (log == null) return null;
    switch (log.overallStatus) {
      case 'Taken':
        return _green;
      case 'Missed':
        return _red;
      case 'Partial':
        return _amber;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medication Calendar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── HEADER ────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Calendar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Track your daily doses, stay on schedule.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── CALENDAR ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) =>
                          _selectedDay != null &&
                          d.year == _selectedDay!.year &&
                          d.month == _selectedDay!.month &&
                          d.day == _selectedDay!.day,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                          _selectedLog = _logMap[_key(selected)];
                        });
                      },
                      onPageChanged: (focused) {
                        setState(() => _focusedDay = focused);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: false,
                        titleTextStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF2D3748),
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: _blue.withValues(alpha:0.15),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final color = _dayColor(day);
                          if (color == null) return null;
                          final isTaken = color == _green;
                          final isMissed = color == _red;
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isTaken
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : isMissed
                                  ? const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── LEGEND ────────────────────────────
                  const ComplianceLegend(),
                  const SizedBox(height: 16),

                  // ── SELECTED DAY DETAIL ───────────────
                  if (_selectedDay != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _selectedLog != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formattedDate(_selectedDay!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._selectedLog!.medicines.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _blue,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Rx',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${m.drugName} (${m.strength})',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'Instruction: Take with water after meal',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          m.isTaken
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: m.isTaken ? _green : _red,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (!_selectedLog!.isFullyTaken &&
                                    _selectedDay!.day == DateTime.now().day &&
                                    _selectedDay!.month == DateTime.now().month)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await MedicationRepository.instance
                                              .markAllTaken(
                                                takenAt: DateTime.now(), fullRegimen: [],
                                              );
                                          _loadHistory();
                                        } catch (_) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Mark as Taken'),
                                    ),
                                  ),
                              ],
                            )
                          : Text(
                              'No log found for ${_formattedDate(_selectedDay!)}.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formattedDate(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

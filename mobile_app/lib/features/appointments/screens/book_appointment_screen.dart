import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../widgets/slot_picker.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const _blue = Color(0xFF1A73E8);
  static const _navy = Color(0xFF1A3A5C);
  static const _green = Color(0xFF34A853);

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  String _purpose = 'Follow-up';
  final _notesController = TextEditingController();
  bool _loading = false;
  bool _slotsLoading = false;
  List<DateTime> _availableSlots = [];

  static const _purposes = ['Follow-up', 'Sputum Test', 'Emergency', 'Routine'];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _slotsLoading = true;
      _availableSlots = [];
      _selectedTime = null;
    });
    try {
      final slots = await AppointmentRepository.instance.getAvailableSlots(
        healthCenterId: 'HC-001',
        date: _selectedDate,
      );
      setState(() => _availableSlots = slots);
    } catch (_) {
      // Use fallback mock slots if endpoint not available
      setState(() {
        _availableSlots = [
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            8,
            0,
          ),
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            9,
            0,
          ),
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            10,
            0,
          ),
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            14,
            0,
          ),
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            15,
            0,
          ),
        ];
      });
    } finally {
      setState(() => _slotsLoading = false);
    }
  }

  Future<void> _book() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AppointmentRepository.instance.book(
        scheduledDate: _selectedDate,
        scheduledTime: _selectedTime!,
        purpose: _purpose,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment requested successfully!'),
            backgroundColor: _green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
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
          'Book Appointment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──────────────────────────────────
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
                    'Schedule a Visit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select a date, time, and purpose for your visit.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── PURPOSE ──────────────────────────────────
            _Label(text: 'Purpose of Visit'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Wrap(
                children: _purposes.map((p) {
                  final selected = p == _purpose;
                  return GestureDetector(
                    onTap: () => setState(() => _purpose = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _blue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── DATE & TIME PICKER ───────────────────────
            _Label(text: 'Select Date & Time'),
            const SizedBox(height: 10),
            SlotPicker(
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              availableSlots: _availableSlots,
              isLoading: _slotsLoading,
              onDateChanged: (d) {
                setState(() => _selectedDate = d);
                _loadSlots();
              },
              onTimeSelected: (t) => setState(() => _selectedTime = t),
            ),
            const SizedBox(height: 20),

            // ── NOTES ────────────────────────────────────
            _Label(text: 'Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for visit or special concerns...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _blue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── SUMMARY ───────────────────────────────────
            if (_selectedTime != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Summary',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      icon: Icons.medical_services_outlined,
                      text: _purpose,
                    ),
                    const SizedBox(height: 4),
                    _SummaryRow(
                      icon: Icons.calendar_today_outlined,
                      text: _formattedDate(_selectedDate),
                    ),
                    const SizedBox(height: 4),
                    _SummaryRow(
                      icon: Icons.access_time_rounded,
                      text: _selectedTime!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── SUBMIT ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Request Appointment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime d) {
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
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF2D3748),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFF34A853)),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
      ),
    ],
  );
}

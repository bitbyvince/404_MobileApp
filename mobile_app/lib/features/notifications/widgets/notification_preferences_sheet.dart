import 'package:flutter/material.dart';

class NotificationPreferencesSheet extends StatefulWidget {
  final bool medicationReminder;
  final bool appointmentReminder;
  final bool sputumReminder;
  final bool alertsEnabled;
  final int reminderHour;
  final int reminderMinute;
  final void Function({
    bool? medicationReminder,
    bool? appointmentReminder,
    bool? sputumReminder,
    bool? alerts,
    int? reminderHour,
    int? reminderMinute,
  })
  onSave;

  const NotificationPreferencesSheet({
    super.key,
    required this.medicationReminder,
    required this.appointmentReminder,
    required this.sputumReminder,
    required this.alertsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onSave,
  });

  @override
  State<NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends State<NotificationPreferencesSheet> {
  late bool _medicationReminder;
  late bool _appointmentReminder;
  late bool _sputumReminder;
  late bool _alertsEnabled;
  late int _reminderHour;
  late int _reminderMinute;

  @override
  void initState() {
    super.initState();
    _medicationReminder = widget.medicationReminder;
    _appointmentReminder = widget.appointmentReminder;
    _sputumReminder = widget.sputumReminder;
    _alertsEnabled = widget.alertsEnabled;
    _reminderHour = widget.reminderHour;
    _reminderMinute = widget.reminderMinute;
  }

  String get _formattedTime {
    final hour = _reminderHour;
    final minute = _reminderMinute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DRAG HANDLE ──────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notification Preferences',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),

          // ── TOGGLES ──────────────────────────────────────
          _PreferenceToggle(
            icon: Icons.medication_outlined,
            iconColor: const Color(0xFF34A853),
            label: 'Medication Reminders',
            subtitle: 'Daily reminder to take your medicine',
            value: _medicationReminder,
            onChanged: (v) => setState(() => _medicationReminder = v),
          ),
          if (_medicationReminder) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: GestureDetector(
                onTap: _pickTime,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Remind me at $_formattedTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: Color(0xFF1A73E8),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 20),
          _PreferenceToggle(
            icon: Icons.event_outlined,
            iconColor: const Color(0xFF1A73E8),
            label: 'Appointment Reminders',
            subtitle: 'Reminders for upcoming appointments',
            value: _appointmentReminder,
            onChanged: (v) => setState(() => _appointmentReminder = v),
          ),
          const Divider(height: 20),
          _PreferenceToggle(
            icon: Icons.science_outlined,
            iconColor: const Color(0xFF9C27B0),
            label: 'Sputum Test Reminders',
            subtitle: 'Alerts when sputum test is approaching',
            value: _sputumReminder,
            onChanged: (v) => setState(() => _sputumReminder = v),
          ),
          const Divider(height: 20),
          _PreferenceToggle(
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFE53935),
            label: 'Health Alerts',
            subtitle: 'Important alerts from your health center',
            value: _alertsEnabled,
            onChanged: (v) => setState(() => _alertsEnabled = v),
          ),
          const SizedBox(height: 20),

          // ── SAVE BUTTON ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  medicationReminder: _medicationReminder,
                  appointmentReminder: _appointmentReminder,
                  sputumReminder: _sputumReminder,
                  alerts: _alertsEnabled,
                  reminderHour: _reminderHour,
                  reminderMinute: _reminderMinute,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Preferences',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _PreferenceToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1A73E8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

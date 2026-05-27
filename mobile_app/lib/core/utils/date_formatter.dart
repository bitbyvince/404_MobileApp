// lib/utils/date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  // ─── DISPLAY FORMATS ─────────────────────────────────────────────────────

  // "May 12, 2026"
  static String toReadable(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // "May 12, 2026 8:00 AM"
  static String toReadableWithTime(DateTime date) {
    return DateFormat('MMMM d, yyyy h:mm a').format(date);
  }

  // "05/12/2026"
  static String toShort(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  // "Mon, May 12"
  static String toDayMonth(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  // "8:00 AM"
  static String toTimeOnly(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // "2026-05-12" — used for API calls and calendar queries
  static String toApiFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ─── RELATIVE TIME ───────────────────────────────────────────────────────

  // "Just now", "3 minutes ago", "2 hours ago", "Yesterday", "May 12"
  static String toRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return toReadable(date);
  }

  // ─── PARSE FROM STRING ───────────────────────────────────────────────────

  // Safely parse ISO date string from backend — returns null if invalid
  static DateTime? fromIso(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Parse and format in one step — returns fallback if parsing fails
  static String fromIsoToReadable(String? dateString, {String fallback = '—'}) {
    final date = fromIso(dateString);
    if (date == null) return fallback;
    return toReadable(date);
  }

  // ─── TREATMENT CALENDAR HELPERS ──────────────────────────────────────────

  // "May 2026" — used for monthly calendar header
  static String toMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // "2026-05" — used for ?month= query param in calendar API
  static String toMonthParam(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }
}

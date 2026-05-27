/// Central registry of all named routes in the RespiraTrack patient app.
/// Always navigate using these constants — never raw strings.
///
/// Usage:
///   Navigator.pushNamed(context, RouteNames.dashboard);
///   Navigator.pushNamed(context, RouteNames.pinEntry, arguments: { ... });
abstract class RouteNames {
  RouteNames._();

  // ── Splash ─────────────────────────────────────────────
  static const String splash = '/';

  // ── Auth ───────────────────────────────────────────────
  static const String login = '/login';
  static const String pinEntry = '/login/pin';
  static const String accountRecovery = '/login/recovery';

  // ── Main ───────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ── Medication ─────────────────────────────────────────
  static const String medication = '/medication';
  static const String complianceCalendar = '/medication/calendar';

  // ── Symptoms ───────────────────────────────────────────
  static const String symptomLog = '/symptoms/log';

  // ── Appointments ───────────────────────────────────────
  static const String appointments = '/appointments';
  static const String bookAppointment = '/appointments/book';

  // ── Notifications ──────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Sputum ─────────────────────────────────────────────
  static const String sputum = '/sputum';

  // ── Profile ────────────────────────────────────────────
  static const String profile = '/profile';
  static const String healthRecords = '/profile/health-records';
}

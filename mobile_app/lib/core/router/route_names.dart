/// Central registry of all named routes in the RespiraTrack patient app.
/// Always navigate using these constants — never raw strings.
///
/// Usage:
///   Navigator.pushNamed(context, RouteNames.dashboard);
///   Navigator.pushNamed(context, RouteNames.pinEntry, arguments: { ... });
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String pinEntry = '/pin';
  static const String accountRecovery = '/recovery';
  static const String dashboard = '/dashboard';
  static const String medication = '/medication';
  static const String complianceCalendar = '/medication/calendar';
  static const String symptoms = '/symptoms';
  static const String symptomLog = '/symptoms';
  static const String appointments = '/appointments';
  static const String bookAppointment = '/appointments/book';
  static const String notifications = '/notifications';
  static const String sputum = '/sputum';
  static const String profile = '/profile';
  static const String healthRecords = '/profile/records';
}

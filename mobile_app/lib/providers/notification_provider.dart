import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../data/repositories/notification_repository.dart';
import '../data/models/notification_model.dart';
import '../services/notification_service.dart';

enum NotificationProviderStatus { initial, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  NotificationProvider({required NotificationRepository notificationRepository})
    : _notificationRepository = notificationRepository;

  // ── STATE ────────────────────────────────────────────────
  NotificationProviderStatus _status = NotificationProviderStatus.initial;
  String? _errorMessage;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  bool _medicationReminderEnabled = true;
  bool _appointmentReminderEnabled = true;
  bool _sputumReminderEnabled = true;
  bool _alertsEnabled = true;
  TimeOfDay _medicationReminderTime = const TimeOfDay(hour: 8, minute: 0);

  bool _hasMore = true;
  int _page = 1;
  bool _isLoadingMore = false;

  String? _fcmToken;

  // ── GETTERS ──────────────────────────────────────────────
  NotificationProviderStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoading => _status == NotificationProviderStatus.loading;
  String? get fcmToken => _fcmToken;

  bool get medicationReminderEnabled => _medicationReminderEnabled;
  bool get appointmentReminderEnabled => _appointmentReminderEnabled;
  bool get sputumReminderEnabled => _sputumReminderEnabled;
  bool get alertsEnabled => _alertsEnabled;
  TimeOfDay get medicationReminderTime => _medicationReminderTime;

  // ── INIT ─────────────────────────────────────────────────
  Future<void> init({required String userId}) async {
    try {
      // NotificationService.initialize handles permission + token registration
      await NotificationService.initialize(userId: userId);

      // Listen for foreground FCM messages via static stream
      NotificationService.inboxStream(userId).listen((incoming) {
        // inboxStream returns full list snapshots — refresh on any change
        loadUnreadCount();
      });

      await loadUnreadCount();
    } catch (_) {
      // Non-fatal — app works without push notifications
    }
  }

  // ── LOAD NOTIFICATIONS ───────────────────────────────────
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _notifications = [];
      _page = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;
    if (_isLoadingMore) return;

    if (_notifications.isEmpty) {
      _setStatus(NotificationProviderStatus.loading);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    _clearError();
    try {
      final result = await _notificationRepository.getNotifications(
        page: _page,
        limit: 20,
      );
      _notifications.addAll(result.notifications);
      _hasMore = result.hasMore;
      _page++;
      _setStatus(NotificationProviderStatus.loaded);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── LOAD UNREAD COUNT ────────────────────────────────────
  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationRepository.getUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (_) {}
  }

  // ── MARK SINGLE AS READ ──────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      final index = _notifications.indexWhere(
        (n) => n.notificationId == notificationId,
      );
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── MARK ALL AS READ ─────────────────────────────────────
  Future<void> markAllAsRead({required String userId}) async {
    try {
      await NotificationService.markAllRead(userId);
      await _notificationRepository.markAllAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── SCHEDULE LOCAL MEDICATION REMINDER ──────────────────
  Future<void> scheduleMedicationReminder({
    required TimeOfDay time,
    required List<String> drugNames,
  }) async {
    try {
      // Local scheduling is handled by flutter_local_notifications
      // directly — wire this up in notification_service.dart if needed
      _medicationReminderTime = time;
      _medicationReminderEnabled = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── CANCEL LOCAL MEDICATION REMINDER ────────────────────
  Future<void> cancelMedicationReminder() async {
    try {
      _medicationReminderEnabled = false;
      notifyListeners();
    } catch (_) {}
  }

  // ── UPDATE PREFERENCES ───────────────────────────────────
  Future<void> updatePreferences({
    required String userId,
    bool? medicationReminder,
    bool? appointmentReminder,
    bool? sputumReminder,
    bool? alerts,
    TimeOfDay? reminderTime,
  }) async {
    if (medicationReminder != null) {
      _medicationReminderEnabled = medicationReminder;
      if (!medicationReminder) await cancelMedicationReminder();
    }
    if (appointmentReminder != null)
      _appointmentReminderEnabled = appointmentReminder;
    if (sputumReminder != null) _sputumReminderEnabled = sputumReminder;
    if (alerts != null) _alertsEnabled = alerts;
    if (reminderTime != null) _medicationReminderTime = reminderTime;

    try {
      await NotificationService.updatePreferences(
        userId: userId,
        preferences: {
          'medication_reminder': {
            'enabled': _medicationReminderEnabled,
            'time':
                '${_medicationReminderTime.hour.toString().padLeft(2, '0')}:'
                '${_medicationReminderTime.minute.toString().padLeft(2, '0')}',
          },
          'appointment_reminder': {'enabled': _appointmentReminderEnabled},
          'sputum_test_reminder': {'enabled': _sputumReminderEnabled},
        },
      );
    } catch (_) {}

    notifyListeners();
  }

  // ── LOAD PREFERENCES ─────────────────────────────────────
  Future<void> loadPreferences({required String userId}) async {
    try {
      final prefs = await NotificationService.getPreferences(userId);
      if (prefs == null) return;

      final medPref = prefs['medication_reminder'] as Map<String, dynamic>?;
      final apptPref = prefs['appointment_reminder'] as Map<String, dynamic>?;
      final sputPref = prefs['sputum_test_reminder'] as Map<String, dynamic>?;

      _medicationReminderEnabled = medPref?['enabled'] as bool? ?? true;
      _appointmentReminderEnabled = apptPref?['enabled'] as bool? ?? true;
      _sputumReminderEnabled = sputPref?['enabled'] as bool? ?? true;

      final timeStr = medPref?['time'] as String? ?? '08:00';
      final parts = timeStr.split(':');
      _medicationReminderTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );

      notifyListeners();
    } catch (_) {}
  }

  // ── RESOLVE ROUTE FROM NOTIFICATION ──────────────────────
  String resolveNotificationRoute(NotificationModel notification) {
    switch (notification.type) {
      case 'medication_reminder':
      case 'missed_dose':
        return '/medication';
      case 'appointment_confirmed':
      case 'appointment_reminder':
        return '/appointments';
      case 'sputum_test_due':
        return '/sputum';
      default:
        return '/notifications';
    }
  }

  // ── RESET (on logout) ────────────────────────────────────
  Future<void> reset({required String userId}) async {
    await NotificationService.deregisterToken();
    _status = NotificationProviderStatus.initial;
    _errorMessage = null;
    _notifications = [];
    _unreadCount = 0;
    _hasMore = true;
    _page = 1;
    _isLoadingMore = false;
    _fcmToken = null;
    notifyListeners();
  }

  // ── PRIVATE HELPERS ──────────────────────────────────────
  void _setStatus(NotificationProviderStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = NotificationProviderStatus.error;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  void clearError() {
    _clearError();
    notifyListeners();
  }
}

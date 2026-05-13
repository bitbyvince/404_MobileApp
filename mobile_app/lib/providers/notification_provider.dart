// lib/providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../models/alert.model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => _alerts;
  List<Alert> get unread => _alerts.where((a) => !a.isRead).toList();
  int get unreadCount => unread.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── FETCH ALERTS ─────────────────────────────────────────────────────────

  Future<void> fetchAlerts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _service.getAlerts(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── MARK AS READ ─────────────────────────────────────────────────────────

  void markRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllRead() {
    _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  // ─── CLEAR ────────────────────────────────────────────────────────────────

  void clear() {
    _alerts = [];
    notifyListeners();
  }
}

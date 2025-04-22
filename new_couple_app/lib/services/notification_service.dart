import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  bool _notificationsEnabled = true;
  static const String _prefsKey = 'notifications_enabled';

  NotificationService() {
    _loadSettings();
  }

  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_prefsKey) ?? true;
      notifyListeners();
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _notificationsEnabled);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
    
    notifyListeners();
  }

  // 알림 전송 메서드 (실제 구현시 필요)
  Future<void> sendNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;
    
    // 여기에 실제 알림 전송 로직 구현
    // 예: Firebase Cloud Messaging 또는 local notifications
    print('Notification sent: $title - $body');
  }
}

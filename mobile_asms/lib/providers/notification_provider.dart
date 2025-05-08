import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../config/api_config.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    print('NotificationProvider created');
  }
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fetch user notifications
  Future<void> fetchNotifications(int userId) async {
    print('NOTIFICATION PROVIDER: fetchNotifications called');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/notifications/$userId');
      print('API response: $response');

      final List<dynamic> notificationData = response['data']['notifications'];
      _notifications = notificationData
          .map((data) => NotificationModel.fromJson(data))
          .toList();
      print('Parsed notifications: $_notifications');

      _unreadCount =
          _notifications.where((notification) => !notification.isRead).length;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      print('Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.post(
        ApiConfig.notificationRead,
        {'notificationId': notificationId},
      );

      // Find and update the notification in the list
      final index = _notifications
          .indexWhere((notification) => notification.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        if (!notification.isRead) {
          _notifications[index] = notification.copyWith(isRead: true);
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          notifyListeners();
        }
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      await _apiService.post(
        ApiConfig.notificationRead,
        {'markAll': true},
      );

      // Update all notifications in the list
      _notifications = _notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Show a local notification
  Future<void> showLocalNotification(String title, String body,
      {String? payload}) async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  // Schedule a notification
  Future<void> scheduleLocalNotification(
      String title, String body, DateTime scheduledDate,
      {String? payload}) async {
    await _notificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  // Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _notificationService.setNotificationEnabled(enabled);
    notifyListeners();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.isNotificationEnabled();
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    return await _notificationService.requestPermissions();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Filter notifications by type
  List<NotificationModel> filterNotificationsByType(String type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  // Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }
}

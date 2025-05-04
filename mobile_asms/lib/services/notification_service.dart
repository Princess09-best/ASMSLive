import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Initialize timezone and notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    // Initialize settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
  }
  
  // Request notification permissions - simplified approach
  Future<bool> requestPermissions() async {
    // For Android, we'll simply check the permissions
    try {
      // For iOS
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
            
      // Request iOS permissions
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      return result ?? true;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }
  
  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await isNotificationEnabled()) {
      return;
    }
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'asms_channel_id',
      'ASMS Notifications',
      channelDescription: 'Notifications for ASMS app',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
  
  // Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!await isNotificationEnabled()) {
      return;
    }
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'asms_channel_id',
      'ASMS Notifications',
      channelDescription: 'Notifications for ASMS app',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Check if notifications are enabled
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_enabled') ?? true;
  }
  
  // Enable or disable notifications
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', enabled);
  }
  
  // Schedule deadline reminder for a scholarship
  Future<void> scheduleDeadlineReminder({
    required int scholarshipId,
    required String scholarshipName,
    required DateTime deadline,
    int daysBeforeDeadline = 3,
  }) async {
    final reminderDate = deadline.subtract(Duration(days: daysBeforeDeadline));
    
    // Only schedule if the reminder date is in the future
    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: scholarshipId,
        title: 'Scholarship Deadline Reminder',
        body: 'The application deadline for $scholarshipName is approaching in $daysBeforeDeadline days!',
        scheduledDate: reminderDate,
        payload: 'scholarship:$scholarshipId',
      );
    }
  }
  
  // Show notification for application status update
  Future<void> showApplicationStatusNotification({
    required int applicationId,
    required String scholarshipName,
    required String status,
  }) async {
    String title;
    String body;
    
    switch (status) {
      case 'submitted':
        title = 'Application Submitted';
        body = 'Your application for $scholarshipName has been successfully submitted.';
        break;
      case 'under-review':
        title = 'Application Status Update';
        body = 'Your application for $scholarshipName is now under review.';
        break;
      case 'approved':
        title = 'Congratulations!';
        body = 'Your application for $scholarshipName has been approved!';
        break;
      case 'rejected':
        title = 'Application Status Update';
        body = 'Unfortunately, your application for $scholarshipName was not approved.';
        break;
      default:
        title = 'Application Status Update';
        body = 'Your application for $scholarshipName has been updated.';
    }
    
    await showNotification(
      id: applicationId,
      title: title,
      body: body,
      payload: 'application:$applicationId',
    );
  }
} 
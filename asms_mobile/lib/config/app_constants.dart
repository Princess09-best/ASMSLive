import 'package:flutter/material.dart';

class AppConstants {
  // App information
  static const String appName = 'ASMS Mobile';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String userInfoKey = 'user_info';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String notificationEnabledKey = 'notification_enabled';
  
  // Theme colors
  static const Color primaryColor = Color(0xFFB71C1C); // Dark Red
  static const Color accentColor = Color(0xFF8B0000); // Darker Red
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color textPrimaryColor = Color(0xFF212121); // Almost Black
  static const Color textSecondaryColor = Color(0xFF757575); // Gray
  static const Color cardColor = Color(0xFFF5F5F5); // Light Gray
  
  // Functional colors
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFFFA000); // Amber
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Biometric authentication related
  static const String biometricReason = 'Authenticate to access your ASMS account';
  
  // Notification related
  static const String notificationChannelId = 'asms_notifications';
  static const String notificationChannelName = 'ASMS Notifications';
  static const String notificationChannelDescription = 'Notifications from ASMS app';
} 
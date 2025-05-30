class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'http://172.16.5.8/ASMSLive/api';

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/update';

  // Scholarship endpoints
  static const String scholarships = '/scholarship/list';
  static const String scholarshipDetails = '/scholarship/details';

  // Application endpoints
  static const String applications = '/applications';
  static const String applicationDetails = '/applications/';
  static const String submitApplication = '/applications';
  static const String applicationStatus = '/applications/';

  // Document endpoints
  static const String documents = '/document/list';
  static const String uploadDocument = '/document/upload';
  static const String documentDetails = '/document/details';

  // Notification endpoints
  static const String notifications = '/notification/list';
  static const String notificationRead = '/notification/read';
}

import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type; // info, warning, success, error
  final DateTime createdAt;
  final bool isRead;
  final String? actionType; // view-application, view-scholarship, etc.
  final int? actionId; // ID of the related item

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actionType,
    this.actionId,
  });

  // Factory constructor to create a NotificationModel object from a JSON map
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['ID']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['UserID']?.toString() ?? '') ?? 0,
      title: json['Title'] ?? '',
      message: json['Message'] ?? '',
      type: json['Type'] ?? '',
      createdAt:
          DateTime.parse(json['CreatedAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['IsRead'] == '1' ||
          json['IsRead'] == 1 ||
          json['IsRead'] == true,
      actionType: json['ActionType'],
      actionId: json['ActionId'] != null
          ? int.tryParse(json['ActionId'].toString())
          : null,
    );
  }

  // Convert NotificationModel object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'actionType': actionType,
      'actionId': actionId,
    };
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? actionType,
    int? actionId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
    );
  }

  // Get formatted creation date
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(createdAt);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Get icon data for the notification type
  String get iconData {
    switch (type) {
      case 'info':
        return 'info';
      case 'warning':
        return 'warning';
      case 'success':
        return 'check_circle';
      case 'error':
        return 'error';
      default:
        return 'notifications';
    }
  }

  // Get color for the notification type
  String get color {
    switch (type) {
      case 'info':
        return '#3498db'; // Blue
      case 'warning':
        return '#f39c12'; // Orange
      case 'success':
        return '#2ecc71'; // Green
      case 'error':
        return '#e74c3c'; // Red
      default:
        return '#95a5a6'; // Gray
    }
  }
}

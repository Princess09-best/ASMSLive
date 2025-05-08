import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/notification_tile.dart';
import '../providers/auth_provider.dart';
import '../screens/bank_details_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;

  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
    _startShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeDetection() {
    const double shakeThreshold = 15.0;
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!) > Duration(seconds: 2)) {
          _lastShakeTime = now;
          _onShake();
        }
      }
    });
  }

  void _onShake() {
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Refreshing notifications (shake detected)!')),
      );
    }
  }

  Future<void> _loadNotifications() async {
    print('NOTIFICATION SCREEN: _loadNotifications called');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'User not logged in.';
        });
        return;
      }
      print('Loading notifications...');
      print('User ID: $userId');

      print(
          'About to call fetchNotifications on provider: $notificationProvider');

      await notificationProvider.fetchNotifications(userId);
    } catch (e) {
      print('Error in _loadNotifications: $e');
      setState(() {
        _error = 'Failed to load notifications. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      // Mark as read if not already read
      if (!notification.isRead) {
        await notificationProvider.markAsRead(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification marked as read')),
          );
        }
      }

      final type = notification.type.toLowerCase();
      final title = notification.title.toLowerCase();
      final message = notification.message.toLowerCase();

      final isDisbursed =
          title.contains('disbursed') || message.contains('disbursed');
      final isApproved = (type == 'success' ||
              title.contains('approved') ||
              message.contains('approved')) &&
          !isDisbursed;
      final isRejected = type == 'error' ||
          type == 'warning' ||
          title.contains('rejected') ||
          message.contains('rejected');

      if (notification.actionType == 'view-application' &&
          notification.actionId != null &&
          isApproved) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BankDetailsScreen(applicationId: notification.actionId!),
          ),
        );
      } else if (isDisbursed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your scholarship has been disbursed!')),
        );
      } else if (isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This application was not approved.')),
        );
      }
      // For other types, do nothing or handle as needed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final hasUnread =
                  notificationProvider.notifications.any((n) => !n.isRead);
              if (hasUnread) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: () async {
                    await notificationProvider.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('All notifications marked as read')),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 200),
                      Center(child: Text('No notifications yet')),
                    ],
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationTile(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

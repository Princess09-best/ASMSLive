import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/notification_tile.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
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
    if (notification.isRead) return;

    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.markAsRead(notification.id);

      // Handle navigation based on action type
      if (notification.actionType != null && notification.actionId != null) {
        switch (notification.actionType) {
          case 'view-application':
            // Navigate to application details
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => ApplicationDetailsScreen(applicationId: notification.actionId!),
            // ));
            break;
          case 'view-scholarship':
            // Navigate to scholarship details
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => ScholarshipDetailsScreen(scholarshipId: notification.actionId!),
            // ));
            break;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark notification as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryColor,
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

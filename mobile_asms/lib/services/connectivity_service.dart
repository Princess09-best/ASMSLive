import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'application_service.dart';
import 'notification_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _connectivitySubscription;
  bool _lastConnectionStatus = false;
  bool _isSyncing = false;

  // Constructor to initialize notification service
  ConnectivityService() {
    _initializeNotificationService();
  }

  // Initialize notification service
  Future<void> _initializeNotificationService() async {
    await _notificationService.initialize();
  }

  // Check if device is connected to the internet
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      print(
          'Connectivity check: ${isConnected ? 'Connected' : 'Disconnected'}');
      return isConnected;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Listen for connectivity changes and call the callback
  void listenToConnectivityChanges(Function(bool) onConnectivityChanged) {
    _connectivitySubscription?.cancel();

    // Check initial connection status
    isConnected().then((connected) {
      _lastConnectionStatus = connected;
    });

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) async {
      final isConnected = result != ConnectivityResult.none;
      print(
          'Connectivity changed: ${isConnected ? 'Connected' : 'Disconnected'}');

      // Only call callback and trigger sync if status changes
      // This prevents sync from running too often
      if (isConnected != _lastConnectionStatus) {
        print(
            'Connection status changed from ${_lastConnectionStatus} to ${isConnected}');
        _lastConnectionStatus = isConnected;
        onConnectivityChanged(isConnected);

        // Automatically sync pending applications when connectivity is restored
        if (isConnected) {
          print('Connectivity restored - syncing pending applications');

          // Avoid multiple concurrent sync operations
          if (_isSyncing) {
            print('Sync already in progress, skipping additional sync');
            return;
          }

          _isSyncing = true;

          try {
            // Show notification about connectivity restoration (optional)
            await _notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch % 100000,
              title: 'Network Connected',
              body:
                  'Your network connection has been restored. Syncing your pending applications...',
              payload: 'network_restored',
            );

            // Sync pending applications (this will handle its own notifications)
            await ApplicationService.syncPendingApplications();
            print('Sync completed after connectivity restored');
          } catch (e) {
            print('Error during auto-sync after connectivity restored: $e');
          } finally {
            _isSyncing = false;
          }
        } else {
          print('Connection lost - sync will be tried when connection returns');

          // Optional: Show notification about lost connectivity
          try {
            await _notificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch % 100000 + 1,
              title: 'Network Disconnected',
              body:
                  'Your network connection was lost. Applications will be synced when connection is restored.',
              payload: 'network_lost',
            );
          } catch (e) {
            print('Error showing network disconnection notification: $e');
          }
        }
      }
    });
  }

  // Manually trigger a sync if connected
  Future<bool> syncIfConnected({int? userId}) async {
    final connected = await isConnected();
    if (connected) {
      // Avoid multiple concurrent sync operations
      if (_isSyncing) {
        print('Sync already in progress, skipping manual sync');
        return false;
      }

      _isSyncing = true;

      try {
        await ApplicationService.syncPendingApplications(userId: userId);
        return true;
      } catch (e) {
        print('Error during manual sync: $e');
        return false;
      } finally {
        _isSyncing = false;
      }
    }
    return false;
  }

  // Dispose of the subscription
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

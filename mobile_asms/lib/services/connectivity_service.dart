import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'application_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _lastConnectionStatus = false;

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
          try {
            await ApplicationService.syncPendingApplications();
            print('Sync completed after connectivity restored');
          } catch (e) {
            print('Error during auto-sync after connectivity restored: $e');
          }
        } else {
          print('Connection lost - sync will be tried when connection returns');
        }
      }
    });
  }

  // Manually trigger a sync if connected
  Future<bool> syncIfConnected() async {
    final connected = await isConnected();
    if (connected) {
      try {
        await ApplicationService.syncPendingApplications();
        return true;
      } catch (e) {
        print('Error during manual sync: $e');
        return false;
      }
    }
    return false;
  }

  // Dispose of the subscription
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

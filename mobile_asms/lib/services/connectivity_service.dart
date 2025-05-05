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
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Listen for connectivity changes and call the callback
  void listenToConnectivityChanges(Function(bool) onConnectivityChanged) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) async {
      final isConnected = result != ConnectivityResult.none;

      // Only call callback and trigger sync if status changes
      // This prevents sync from running too often
      if (isConnected != _lastConnectionStatus) {
        _lastConnectionStatus = isConnected;
        onConnectivityChanged(isConnected);

        // Automatically sync pending applications when connectivity is restored
        if (isConnected) {
          print('Connectivity restored - syncing pending applications');
          await ApplicationService.syncPendingApplications();
        }
      }
    });
  }

  // Dispose of the subscription
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

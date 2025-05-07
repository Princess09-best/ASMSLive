import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'application_service.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _connectivitySubscription;
  bool _lastConnectionStatus = false;
  bool _isSyncing = false;
  // Track the last time we processed a connectivity change
  DateTime? _lastConnectivityChange;
  // Minimum interval between processing connectivity changes (in seconds)
  // Reduced from 2 to 1 second to be more responsive
  final int _connectivityChangeThreshold = 1;

  // Singleton pattern to ensure we have only one instance
  static final ConnectivityService _instance = ConnectivityService._internal();

  // Factory constructor to return the singleton instance
  factory ConnectivityService() {
    return _instance;
  }

  // Private constructor for singleton
  ConnectivityService._internal() {
    _initialize();
  }

  // Initialize the service
  Future<void> _initialize() async {
    print('Initializing ConnectivityService');
    await _initializeNotificationService();
    // Check initial connection status
    _lastConnectionStatus = await isConnected();
    print(
        'Initial connection status: ${_lastConnectionStatus ? "Connected" : "Disconnected"}');

    // Immediately start listening for connectivity changes
    _startMonitoringConnectivity();
  }

  // Initialize notification service
  Future<void> _initializeNotificationService() async {
    await _notificationService.initialize();
    print('NotificationService initialized');
  }

  // Check if device is connected to the internet
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      print(
          'Connectivity check: ${isConnected ? 'Connected' : 'Disconnected'} (${result.toString()})');
      return isConnected;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Start monitoring connectivity changes
  void _startMonitoringConnectivity() {
    // Cancel existing subscription if any
    _connectivitySubscription?.cancel();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      // Log the actual connectivity result we received
      print('Connectivity change detected: ${result.toString()}');
      // Trigger a connectivity check
      _checkAndHandleConnectivityChange();
    });

    print('Connectivity change listener registered');

    // Force an immediate check to ensure we're in sync
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAndHandleConnectivityChange();
    });
  }

  // Check connectivity and handle any changes
  Future<void> _checkAndHandleConnectivityChange() async {
    try {
      // Get current connectivity status
      bool isConnected = await this.isConnected();

      // Apply rate limiting to avoid processing too many events
      final now = DateTime.now();
      if (_lastConnectivityChange != null) {
        final diff = now.difference(_lastConnectivityChange!).inSeconds;
        if (diff < _connectivityChangeThreshold) {
          print(
              'Ignoring connectivity change event - too soon after previous event ($diff seconds)');
          return;
        }
      }
      _lastConnectivityChange = now;

      print(
          'Processing connectivity change: currently ${isConnected ? "Connected" : "Disconnected"}, previous state: ${_lastConnectionStatus ? "Connected" : "Disconnected"}');

      // Handle connectivity change regardless of previous state to be more robust
      if (isConnected) {
        print('Device is connected - syncing applications if needed');

        // Update status before sync
        bool wasConnected = _lastConnectionStatus;
        _lastConnectionStatus = isConnected;

        // Notify all registered UI callbacks
        _notifyCallbacks(isConnected);

        // Always try to sync when we detect a connection
        // This ensures we don't miss any sync opportunities
        print('Connection detected - triggering sync');
        await _syncApplicationsAfterConnectivityRestored();
      } else {
        print('Device is disconnected');

        // Only notify and show message if this is a new disconnection
        if (_lastConnectionStatus != isConnected) {
          print('Connection lost - sync will be tried when connection returns');

          // Update status
          _lastConnectionStatus = isConnected;

          // Notify all registered UI callbacks
          _notifyCallbacks(isConnected);

          // Show notification about lost connectivity
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
        } else {
          print('Still disconnected - waiting for connectivity');
        }
      }
    } catch (e) {
      print('Error checking connectivity status: $e');
    }
  }

  // List of callbacks to notify when connectivity changes
  final List<Function(bool)> _callbacks = [];

  // Notify all registered callbacks
  void _notifyCallbacks(bool isConnected) {
    print(
        'Notifying ${_callbacks.length} UI callbacks of connection state: ${isConnected ? "Connected" : "Disconnected"}');
    for (var callback in _callbacks) {
      try {
        callback(isConnected);
      } catch (e) {
        print('Error notifying callback: $e');
      }
    }
  }

  // Register for connectivity changes
  void listenToConnectivityChanges(Function(bool) onConnectivityChanged) {
    // Add callback to the list if not already present
    if (!_callbacks.contains(onConnectivityChanged)) {
      _callbacks.add(onConnectivityChanged);
      print('UI component registered for connectivity updates');
    }

    // Immediately notify of current status
    onConnectivityChanged(_lastConnectionStatus);
  }

  // Unregister from connectivity changes
  void unregisterConnectivityChanges(Function(bool) onConnectivityChanged) {
    _callbacks.remove(onConnectivityChanged);
    print('UI component unregistered from connectivity updates');
  }

  // Handle syncing applications after connectivity is restored
  Future<void> _syncApplicationsAfterConnectivityRestored() async {
    // Avoid multiple concurrent sync operations
    if (_isSyncing) {
      print('Sync already in progress, skipping additional sync');
      return;
    }

    print('Starting connectivity-triggered sync process');
    _isSyncing = true;

    try {
      // Show notification about connectivity restoration
      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Network Connected',
        body:
            'Your network connection has been restored. Syncing your pending applications...',
        payload: 'network_restored',
      );

      print('Network restoration notification shown, proceeding with sync');

      // Small delay to ensure the first notification is shown before potential sync notifications
      await Future.delayed(const Duration(seconds: 1));

      // Sync pending applications (this will handle its own notifications)
      final result = await ApplicationService.syncPendingApplications();
      print('Sync completed after connectivity restored. Result: $result');
    } catch (e) {
      print('Error during auto-sync after connectivity restored: $e');
    } finally {
      _isSyncing = false;
    }
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

      print('Starting manual sync process' +
          (userId != null ? ' for user $userId' : ''));
      _isSyncing = true;

      try {
        await ApplicationService.syncPendingApplications(userId: userId);
        print('Manual sync completed successfully');
        return true;
      } catch (e) {
        print('Error during manual sync: $e');
        return false;
      } finally {
        _isSyncing = false;
      }
    }
    print('Manual sync skipped - not connected');
    return false;
  }

  // Start listening for connectivity changes immediately,
  // even without a UI callback. This ensures we always sync applications
  // when connectivity is restored, regardless of which screen is active.
  void startListeningForConnectivity() {
    // This is now redundant as we start listening in _initialize
    // but kept for backwards compatibility
    print('Ensuring connectivity monitoring is active');

    // Force a check and restart listener if needed
    if (_connectivitySubscription == null) {
      _startMonitoringConnectivity();
    } else {
      // Force a fresh connectivity check
      _checkAndHandleConnectivityChange();
    }
  }

  // Force a connectivity check and sync if needed
  Future<void> forceConnectivityCheckAndSync() async {
    print('Forcing connectivity check and sync');
    final isConnected = await this.isConnected();

    if (isConnected) {
      if (_isSyncing) {
        print('Force check - connected but sync already in progress, waiting');
        // Wait for current sync to finish then try again
        await Future.delayed(const Duration(seconds: 3));
        if (!_isSyncing) {
          print('Previous sync completed, starting forced sync');
          await _syncApplicationsAfterConnectivityRestored();
        }
      } else {
        print(
            'Force check - connection status is connected, syncing applications');
        await _syncApplicationsAfterConnectivityRestored();
      }
    } else {
      print('Force check - not connected, skipping sync');
    }
  }

  // Dispose of the subscription and callbacks
  void dispose() {
    _connectivitySubscription?.cancel();
    _callbacks.clear();
    print('ConnectivityService disposed');
  }
}

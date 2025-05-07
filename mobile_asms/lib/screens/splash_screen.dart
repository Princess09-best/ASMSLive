import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/connectivity_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize connectivity monitoring
    _connectivityService.listenToConnectivityChanges((isConnected) {
      // Update UI or state if needed
      if (mounted) {
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        if (isConnected) {
          notificationProvider.showLocalNotification(
            'Network Connected',
            'Your network connection has been restored.',
            payload: 'network_status',
          );
        }
      }
    });

    // Add a small delay for splash screen visibility
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkLoginStatus();

    if (!mounted) return;

    // Navigate based on login status
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA20000),
      body: Center(
        child: Image.asset('assets/images/white_on_trans.png'), // Use your logo
      ),
    );
  }
}

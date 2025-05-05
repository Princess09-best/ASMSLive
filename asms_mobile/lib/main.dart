import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'services/services.dart';

// Models

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Config
import 'config/app_constants.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/scholarship_provider.dart';
import 'providers/application_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScholarshipProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppConstants.primaryColor,
          onPrimary: Colors.white,
          secondary: AppConstants.accentColor,
          onSecondary: Colors.white,
          error: AppConstants.errorColor,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: AppConstants.textPrimaryColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        cardColor: AppConstants.cardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConstants.textSecondaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppConstants.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppConstants.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: AppConstants.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppConstants.textPrimaryColor),
          bodyMedium: TextStyle(color: AppConstants.textPrimaryColor),
        ),
      ),
      home: FutureBuilder<bool>(
        future: Provider.of<AuthProvider>(context, listen: false)
            .checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              ),
            );
          }

          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../widgets/scholarship_card.dart';
import 'scholarships_screen.dart';
import '../services/scholarship_service.dart';
import '../models/scholarship.dart';
import '../services/connectivity_service.dart';
import 'applications_screen.dart';
import '../services/application_service.dart';
import '../providers/auth_provider.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  // Scholarship data
  List<Scholarship> _scholarships = [];
  int _totalScholarships = 0;
  bool _isLoading = true;
  bool _isConnected = true;
  final ConnectivityService _connectivityService = ConnectivityService();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isListeningToConnectivity = false;
  bool _isScreenActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _loadData();

    // Register for connectivity updates
    _connectivityService.listenToConnectivityChanges(_handleConnectivityChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Unregister from connectivity updates
    _connectivityService
        .unregisterConnectivityChanges(_handleConnectivityChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('App resumed - checking connectivity and syncing');
      _isScreenActive = true;
      _checkConnectivityAndSync();
    } else if (state == AppLifecycleState.paused) {
      _isScreenActive = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connectivity and sync when screen becomes active
    if (!_isScreenActive) {
      _isScreenActive = true;
      print('Home screen became active - checking connectivity and syncing');
      _checkConnectivityAndSync();
    }
  }

  // Check connectivity and trigger sync if needed
  Future<void> _checkConnectivityAndSync() async {
    print('Checking connectivity and syncing...');
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });

    if (isConnected) {
      print('Connected - triggering sync');
      await _syncPendingApplicationsForCurrentUser(
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id);
    } else {
      print('Not connected - skipping sync');
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(bool isConnected) {
    print('Connectivity changed: $isConnected');
    setState(() {
      _isConnected = isConnected;
    });

    // Refresh data and sync when connectivity is restored
    if (isConnected) {
      print('Connectivity restored - refreshing data and syncing');
      _refreshData();
      _syncPendingApplicationsForCurrentUser(
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id);
    }
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load scholarships for the home screen
    final scholarships = await ScholarshipService.getScholarships(limit: 2);
    final totalScholarships = await ScholarshipService.getTotalScholarships();

    setState(() {
      _scholarships = scholarships;
      _totalScholarships = totalScholarships;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    // Force refresh data from API
    final scholarships = await ScholarshipService.refreshScholarships(limit: 2);
    final totalScholarships = await ScholarshipService.getTotalScholarships();

    setState(() {
      _scholarships = scholarships;
      _totalScholarships = totalScholarships;
    });
  }

  // Manual sync for when the user initiates it (e.g., via pull-to-refresh)
  Future<void> _syncPendingApplicationsForCurrentUser(int? userId) async {
    try {
      print('Starting sync for user: $userId');
      bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        print('Connected - proceeding with sync');
        await _connectivityService.syncIfConnected(userId: userId);
      } else {
        print('Not connected, skipping application sync');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are offline. Applications will sync when you reconnect.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error syncing applications: $e');
    }
  }

  // Legacy method kept for compatibility
  Future<void> _syncPendingApplications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _syncPendingApplicationsForCurrentUser(authProvider.currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.fullName ?? 'User'),
              accountEmail: Text(user?.email ?? 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.fullName?.isNotEmpty == true)
                      ? user!.fullName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('My Applications'),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('View Scholarships'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScholarshipsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Nearby Scholarships'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            // Add Camera Test option
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera Test'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera_test');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Navigate to settings screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                // Use AuthProvider to handle logout
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScholarshipsScreen(),
                  ),
                );
              },
              backgroundColor: AppConstants.primaryColor,
              child: const Icon(Icons.search, color: Colors.white),
            )
          : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'My Applications';
      case 2:
        return 'Nearby Scholarships';
      case 3:
        return 'Profile';
      default:
        return 'ASMS Mobile';
    }
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const ApplicationsScreen();
      case 2:
        return _buildNearbyTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Network status indicator
            if (!_isConnected)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade800),
                    const SizedBox(width: 8.0),
                    const Expanded(
                      child: Text(
                        'You are offline. Data shown may not be up to date.',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Welcome message
            Text(
              'Welcome back, ${user?.fullName.split(' ').first ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your scholarships easily',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 24),

            // Scholarship Statistics - similar to web dashboard
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Approved Scholarships',
                  '0',
                  Icons.check_circle_outline,
                  Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Disbursed Scholarships',
                  '0',
                  Icons.attach_money,
                  Colors.blue.shade700,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Total Available Scholarships',
                  _isLoading ? '...' : _totalScholarships.toString(),
                  Icons.school_outlined,
                  Colors.orange.shade700,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Available Scholarships
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Scholarships',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScholarshipsScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scholarship cards with real data
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scholarships.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child:
                              Text('No scholarships available at this time.'),
                        ),
                      )
                    : Column(
                        children: _scholarships.map((scholarship) {
                          return Column(
                            children: [
                              ScholarshipCard(
                                id: scholarship.id,
                                name: scholarship.name,
                                provider: scholarship.provider,
                                amount: scholarship.amount,
                                deadline: scholarship.deadline,
                                location: scholarship.location,
                                distance: scholarship.distance,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyTab() {
    // Placeholder for nearby scholarships tab
    return const Center(
      child: Text('Nearby Scholarships - Coming Soon'),
    );
  }

  Widget _buildProfileTab() {
    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Placeholder for profile tab
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 50,
            backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
            child: Text(
              (user?.fullName.isNotEmpty == true)
                  ? user!.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            user?.fullName ?? 'User Name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            user?.email ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 32),

          // Profile actions
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to edit profile screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to biometric settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          const Divider(),
          // Add a refresh data button
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh User Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing user data...')),
              );

              try {
                // Refresh user data by checking login status
                final refreshed = await authProvider.checkLoginStatus();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(refreshed
                        ? 'User data refreshed successfully!'
                        : 'Failed to refresh user data.'),
                    backgroundColor: refreshed ? Colors.green : Colors.red,
                  ),
                );

                // Force a rebuild of the screen
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppConstants.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

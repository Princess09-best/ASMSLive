import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../widgets/scholarship_card.dart';
import 'scholarships_screen.dart';
import 'dart:convert';
import 'dart:io';
import '../models/scholarship.dart';

class ScholarshipService {
  static Future<List<Scholarship>> getScholarships({int limit = 2}) async {
    try {
      // Connect to the real API endpoint
      final uri = Uri.parse('http://10.0.2.2/ASMSLive/api/scholarships');
      print('Fetching scholarships from: $uri');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('API Response status: ${response.statusCode}');
      print(
          'API Response body (first 100 chars): ${responseBody.substring(0, responseBody.length > 100 ? 100 : responseBody.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('scholarships')) {
          final scholarshipsList = data['scholarships'] as List;
          print(
              'Found ${scholarshipsList.length} scholarships in API response');

          // Convert API response to Scholarship objects
          final scholarships = scholarshipsList.map((item) {
            // Make sure data types match our model
            return Scholarship(
              id: item['ID'] is String ? int.parse(item['ID']) : item['ID'],
              name: item['SchemeName'] ?? 'Unknown Scholarship',
              provider: item['Organization'] ?? 'Unknown Provider',
              amount: item['ScholarAmount'] is String
                  ? double.tryParse(item['ScholarAmount'] ?? '0') ?? 0.0
                  : (item['ScholarAmount'] ?? 0.0).toDouble(),
              deadline: item['LastDate'] ?? DateTime.now().toString(),
              location: item['Category'] ?? 'Ghana',
              distance: 0.0, // To be calculated later with geolocation
            );
          }).toList();

          // Return only requested number of scholarships
          return scholarships.take(limit).toList();
        } else {
          print('API response does not contain "scholarships" key');
          return _getSampleScholarships().take(limit).toList();
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        return _getSampleScholarships().take(limit).toList();
      }
    } catch (e) {
      print('Error fetching scholarships: $e');
      return _getSampleScholarships().take(limit).toList();
    }
  }

  // Fallback sample data
  static List<Scholarship> _getSampleScholarships() {
    print('Using sample scholarship data as fallback');
    return [
      Scholarship(
        id: 1,
        name: 'Engineering Excellence Scholarship',
        provider: 'TechFoundation',
        amount: 10000,
        deadline: '2023-12-15',
        location: 'Accra, Ghana',
        distance: 0,
      ),
      Scholarship(
        id: 2,
        name: 'Future Leaders Scholarship',
        provider: 'Global Education Fund',
        amount: 5000,
        deadline: '2023-11-30',
        location: 'Accra, Ghana',
        distance: 0,
      ),
      Scholarship(
        id: 3,
        name: 'Computer Science Innovation Grant',
        provider: 'Digital Africa Initiative',
        amount: 7500,
        deadline: '2023-10-15',
        location: 'Kumasi, Ghana',
        distance: 0,
      ),
    ];
  }

  static Future<int> getTotalScholarships() async {
    try {
      final uri = Uri.parse('http://10.0.2.2/ASMSLive/api/scholarships');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('scholarships')) {
          final scholarshipsList = data['scholarships'] as List;
          return scholarshipsList.length;
        }
      }

      return 5; // Fallback sample count
    } catch (e) {
      print('Error fetching total scholarships: $e');
      return 5; // Fallback sample count
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // Simple user data without Provider
  final Map<String, String> userData = {
    'fullName': 'ASMS User',
    'email': 'user@example.com'
  };

  // Scholarship data
  List<Scholarship> _scholarships = [];
  int _totalScholarships = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userData['fullName'] ?? 'User'),
              accountEmail: Text(userData['email'] ?? 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (userData['fullName']?.isNotEmpty == true)
                      ? userData['fullName']![0].toUpperCase()
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
              onTap: () {
                Navigator.pop(context);
                // Simplified logout - just navigate back to login
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
                // TODO: Navigate to scholarship search/filter screen
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
        return _buildApplicationsTab();
      case 2:
        return _buildNearbyTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'Welcome back, ${userData['fullName']?.split(' ').first ?? 'User'}!',
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
                        child: Text('No scholarships available at this time.'),
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
    );
  }

  Widget _buildApplicationsTab() {
    // Placeholder for applications tab
    return const Center(
      child: Text('My Applications - Coming Soon'),
    );
  }

  Widget _buildNearbyTab() {
    // Placeholder for nearby scholarships tab
    return const Center(
      child: Text('Nearby Scholarships - Coming Soon'),
    );
  }

  Widget _buildProfileTab() {
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
              (userData['fullName']?.isNotEmpty == true)
                  ? userData['fullName']![0].toUpperCase()
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
            userData['fullName'] ?? 'User Name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            userData['email'] ?? 'email@example.com',
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

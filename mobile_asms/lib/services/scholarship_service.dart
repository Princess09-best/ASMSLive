import 'dart:convert';
import 'dart:io';
import '../models/scholarship.dart';
import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScholarshipService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Key for last sync time
  static const String _lastSyncKey = 'last_scholarship_sync';

  // Check if network is available
  static Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Save last sync time
  static Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get last sync time
  static Future<DateTime?> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  // Check if sync is needed (more than 1 hour since last sync)
  static Future<bool> _isSyncNeeded() async {
    final lastSync = await _getLastSyncTime();
    if (lastSync == null) return true;

    final difference = DateTime.now().difference(lastSync);
    return difference.inHours >=
        1; // Sync if last sync was more than 1 hour ago
  }

  // Get scholarships with smart caching strategy
  static Future<List<Scholarship>> getScholarships({int? limit}) async {
    // Try to fetch from network if available and sync is needed
    final isOnline = await _isNetworkAvailable();
    final needsSync = await _isSyncNeeded();

    if (isOnline && needsSync) {
      try {
        final scholarships = await _fetchFromNetwork();

        // If successful, save to local database
        if (scholarships.isNotEmpty) {
          await _dbHelper.clearAllScholarships();
          await _dbHelper.insertAllScholarships(scholarships);
          await _saveLastSyncTime();

          // Return limited results if requested
          if (limit != null && limit > 0) {
            return scholarships.take(limit).toList();
          }
          return scholarships;
        }
      } catch (e) {
        print('Network fetch failed: $e');
        // If network fetch fails, fall back to database
      }
    }

    // Fetch from local database
    final localScholarships = await _dbHelper.getScholarships(limit: limit);

    // If database is empty but we're online, try network fetch regardless of sync time
    if (localScholarships.isEmpty && isOnline) {
      try {
        final scholarships = await _fetchFromNetwork();
        if (scholarships.isNotEmpty) {
          await _dbHelper.insertAllScholarships(scholarships);
          await _saveLastSyncTime();

          // Return limited results if requested
          if (limit != null && limit > 0) {
            return scholarships.take(limit).toList();
          }
          return scholarships;
        }
      } catch (e) {
        print('Fallback network fetch failed: $e');
      }
    }

    // If we still have no data, return sample data
    if (localScholarships.isEmpty) {
      return _getSampleScholarships();
    }

    return localScholarships;
  }

  // Get a specific scholarship by ID
  static Future<Scholarship?> getScholarship(int id) async {
    // Try local database first
    final localScholarship = await _dbHelper.getScholarship(id);
    if (localScholarship != null) {
      return localScholarship;
    }

    // If not found locally and online, try to fetch from network
    if (await _isNetworkAvailable()) {
      try {
        // Connect to the real API endpoint for a single scholarship
        final uri = Uri.parse('http://10.0.2.2/ASMSLive/api/scholarships/$id');
        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);

          if (data.containsKey('scholarship')) {
            final item = data['scholarship'];

            final scholarship = Scholarship(
              id: item['ID'] is String ? int.parse(item['ID']) : item['ID'],
              name: item['SchemeName'] ?? 'Unknown Scholarship',
              provider: item['Organization'] ?? 'Unknown Provider',
              amount: item['ScholarAmount'] is String
                  ? double.tryParse(item['ScholarAmount'] ?? '0') ?? 0.0
                  : (item['ScholarAmount'] ?? 0.0).toDouble(),
              deadline: item['LastDate'] ?? DateTime.now().toString(),
              location: item['Category'] ?? 'Ghana',
              distance: 0.0,
            );

            // Save to database for future offline access
            await _dbHelper.insertScholarship(scholarship);

            return scholarship;
          }
        }
      } catch (e) {
        print('Error fetching single scholarship: $e');
      }
    }

    // If we reach here, return a sample scholarship as fallback
    return _getSampleScholarships().firstWhere((s) => s.id == id,
        orElse: () => _getSampleScholarships().first);
  }

  // Get total scholarship count
  static Future<int> getTotalScholarships() async {
    // Try to get count from network if available
    if (await _isNetworkAvailable()) {
      try {
        final scholarships = await _fetchFromNetwork();
        return scholarships.length;
      } catch (e) {
        print('Error fetching total scholarships from network: $e');
        // Fall back to database count
      }
    }

    // Get count from database
    final count = await _dbHelper.getScholarshipsCount();

    // If database is empty, return sample count
    if (count == 0) {
      return _getSampleScholarships().length;
    }

    return count;
  }

  // Fetch scholarships from network
  static Future<List<Scholarship>> _fetchFromNetwork() async {
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

          return scholarships;
        }
      }

      // If we get here, something went wrong
      throw Exception('Failed to load scholarships from network');
    } catch (e) {
      print('Error in _fetchFromNetwork: $e');
      throw e; // Re-throw to be handled by caller
    }
  }

  // Manually force refresh from network
  static Future<List<Scholarship>> refreshScholarships() async {
    if (!await _isNetworkAvailable()) {
      throw Exception('No network connection available');
    }

    final scholarships = await _fetchFromNetwork();

    // Update local database with fresh data
    await _dbHelper.clearAllScholarships();
    await _dbHelper.insertAllScholarships(scholarships);
    await _saveLastSyncTime();

    return scholarships;
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
}

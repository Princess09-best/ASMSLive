import 'dart:convert';
import 'dart:io';
import '../models/scholarship.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';

class ScholarshipService {
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static Future<List<Scholarship>> getScholarships({int limit = 2}) async {
    try {
      // First check if we're connected to the internet
      bool isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        // Try to fetch from API if connected
        final data = await _fetchFromApi();

        if (data.isNotEmpty) {
          // Cache the fetched data
          await _databaseHelper.insertScholarships(data);
          return data.take(limit).toList();
        }
      }

      // If offline or API call failed, fetch from local database
      print('Fetching scholarships from local database');
      final localData = await _databaseHelper.getScholarshipsWithLimit(limit);

      if (localData.isNotEmpty) {
        return localData;
      }

      // If no local data, return sample data
      return _getSampleScholarships().take(limit).toList();
    } catch (e) {
      print('Error in getScholarships: $e');
      return _getSampleScholarships().take(limit).toList();
    }
  }

  // Fetch data from API
  static Future<List<Scholarship>> _fetchFromApi() async {
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
      return [];
    } catch (e) {
      print('Error fetching from API: $e');
      return [];
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
      // First check if we're connected to the internet
      bool isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        // Try to get count from API if connected
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
      }

      // If offline or API call failed, get count from local database
      return await _databaseHelper.getScholarshipCount();
    } catch (e) {
      print('Error fetching total scholarships: $e');

      // Try to get count from local database
      try {
        return await _databaseHelper.getScholarshipCount();
      } catch (dbError) {
        // Fallback to sample count
        return 5;
      }
    }
  }

  // Force refresh data from API
  static Future<List<Scholarship>> refreshScholarships({int limit = 2}) async {
    try {
      bool isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        final data = await _fetchFromApi();

        if (data.isNotEmpty) {
          // Cache the fetched data
          await _databaseHelper.insertScholarships(data);
          return data.take(limit).toList();
        }
      }

      // If offline or API call failed, return existing data
      return getScholarships(limit: limit);
    } catch (e) {
      print('Error refreshing scholarships: $e');
      return getScholarships(limit: limit);
    }
  }
}

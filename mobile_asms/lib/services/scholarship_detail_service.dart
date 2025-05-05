import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/scholarship.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';

class ScholarshipDetailService {
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a table for full scholarship details in the database
  static Future<void> initDetailDatabase() async {
    final db = await _databaseHelper.database;
    // Check if the table exists
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='scholarship_details'");

    if (tables.isEmpty) {
      await db.execute('''
      CREATE TABLE scholarship_details(
        id INTEGER PRIMARY KEY,
        details TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
      ''');
    }
  }

  // Get scholarship details by ID
  static Future<Map<String, dynamic>?> getScholarshipDetails(int id) async {
    try {
      // Initialize database if needed
      await initDetailDatabase();

      // First check if we're connected to the internet
      bool isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        // Try to fetch from API if connected
        final detailsData = await _fetchDetailsFromApi(id);

        if (detailsData != null) {
          // Cache the fetched data
          await _saveDetailToDatabase(id, detailsData);
          return detailsData;
        }
      }

      // If offline or API call failed, fetch from local database
      print('Fetching scholarship details from local database');
      final localData = await _getDetailFromDatabase(id);

      if (localData != null) {
        return localData;
      }

      // If no local data, check if we have basic scholarship info
      final scholarship = await _databaseHelper.getScholarship(id);
      if (scholarship != null) {
        // Return a simplified details object from the basic scholarship data
        return _createBasicDetailsFromScholarship(scholarship);
      }

      return null;
    } catch (e) {
      print('Error in getScholarshipDetails: $e');
      return null;
    }
  }

  // Fetch data from API
  static Future<Map<String, dynamic>?> _fetchDetailsFromApi(int id) async {
    try {
      // Connect to the real API endpoint
      final uri = Uri.parse('http://172.16.5.8/ASMSLive/api/scholarships/$id');
      print('Fetching scholarship details from: $uri');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('scholarship')) {
          return data['scholarship'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching details from API: $e');
      return null;
    }
  }

  // Save detail to database
  static Future<void> _saveDetailToDatabase(
      int id, Map<String, dynamic> details) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        'scholarship_details',
        {
          'id': id,
          'details': jsonEncode(details),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving scholarship details to database: $e');
    }
  }

  // Get detail from database
  static Future<Map<String, dynamic>?> _getDetailFromDatabase(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'scholarship_details',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        final detailsJson = result.first['details'] as String;
        return jsonDecode(detailsJson);
      }
      return null;
    } catch (e) {
      print('Error getting scholarship details from database: $e');
      return null;
    }
  }

  // Create basic details from scholarship model
  static Map<String, dynamic> _createBasicDetailsFromScholarship(
      Scholarship scholarship) {
    return {
      'ID': scholarship.id,
      'SchemeName': scholarship.name,
      'Organization': scholarship.provider,
      'ScholarAmount': scholarship.amount,
      'LastDate': scholarship.deadline,
      'Category': scholarship.location,
      'ScholarDesc':
          'Limited offline information available. Connect to internet for full details.',
      'Criteria': 'Connect to internet to view full scholarship criteria.',
      'DocomentRequired': 'Connect to internet to view required documents.',
    };
  }
}

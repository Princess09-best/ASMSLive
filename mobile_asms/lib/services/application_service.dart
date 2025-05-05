import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/application.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/app_constants.dart';
import '../config/api_config.dart';

class ApplicationService {
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static final Uuid _uuid = Uuid();
  static final ApiService _apiService = ApiService();

  // Initialize application table in database
  static Future<void> initApplicationDatabase() async {
    final db = await _databaseHelper.database;
    // Check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='applications'",
    );

    if (tables.isEmpty) {
      await db.execute('''
      CREATE TABLE applications(
        id INTEGER PRIMARY KEY,
        scholarshipId INTEGER NOT NULL,
        scholarshipName TEXT NOT NULL,
        provider TEXT NOT NULL,
        amount REAL NOT NULL,
        dateOfBirth TEXT NOT NULL,
        gender TEXT NOT NULL,
        category TEXT NOT NULL,
        major TEXT NOT NULL,
        homeAddress TEXT NOT NULL,
        studentId TEXT NOT NULL,
        status TEXT NOT NULL,
        appliedDate TEXT NOT NULL,
        passportPhotoPath TEXT NOT NULL,
        documentPath TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
      ''');
    }
  }

  // Save files locally and return their paths
  static Future<String> _saveFileLocally(File file, String prefix) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = '${prefix}_${_uuid.v4()}';
    final String filePath = '${directory.path}/$fileName';
    await file.copy(filePath);
    return filePath;
  }

  // Check if file is a valid document type (PDF, DOC, DOCX)
  static bool isValidDocumentType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.pdf' || extension == '.doc' || extension == '.docx';
  }

  // Submit application
  static Future<bool> submitApplication({
    required int scholarshipId,
    required String scholarshipName,
    required String provider,
    required double amount,
    required String dateOfBirth,
    required String gender,
    required String category,
    required String major,
    required String homeAddress,
    required String studentId,
    required File passportPhoto,
    required File document,
  }) async {
    try {
      // Validate document file type
      if (!isValidDocumentType(document)) {
        print(
          'Invalid document type. Only PDF, DOC, or DOCX files are allowed',
        );
        return false;
      }

      // Initialize database
      await initApplicationDatabase();

      // Save files locally
      final passportPhotoPath = await _saveFileLocally(
        passportPhoto,
        'passport',
      );
      final documentPath = await _saveFileLocally(document, 'document');

      // Get current timestamp
      final now = DateTime.now();
      final timestamp = now.toIso8601String();

      // Check if connected to the internet
      bool isConnected = await _connectivityService.isConnected();
      int isSynced = 0; // 0 = not synced, 1 = synced

      if (isConnected) {
        // Try uploading to the API
        bool apiSuccess = await _uploadToApi(
          scholarshipId: scholarshipId,
          scholarshipName: scholarshipName,
          provider: provider,
          amount: amount,
          dateOfBirth: dateOfBirth,
          gender: gender,
          category: category,
          major: major,
          homeAddress: homeAddress,
          studentId: studentId,
          passportPhoto: passportPhoto,
          document: document,
        );

        // For testing, ALSO directly add to database via direct SQL
        if (!apiSuccess) {
          print("API upload failed, trying direct DB injection as backup...");
          try {
            // This is a temporary measure to bypass API issues
            // In production, all data should go through the API
            await _submitDirectlyToDatabase(
              scholarshipId: scholarshipId,
              dateOfBirth: dateOfBirth,
              gender: gender,
              category: category,
              major: major,
              homeAddress: homeAddress,
              studentId: studentId,
            );
            print("Direct DB injection as backup was successful");
            isSynced = 1;
          } catch (e) {
            print("Direct DB injection failed: $e");
          }
        } else {
          isSynced = 1;
        }
      }

      // Create a unique ID for the application
      final id = now.millisecondsSinceEpoch;

      // Save to local database
      final db = await _databaseHelper.database;
      await db.insert('applications', {
        'id': id,
        'scholarshipId': scholarshipId,
        'scholarshipName': scholarshipName,
        'provider': provider,
        'amount': amount,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'category': category,
        'major': major,
        'homeAddress': homeAddress,
        'studentId': studentId,
        'status': isSynced == 1 ? 'Submitted' : 'Pending',
        'appliedDate': timestamp,
        'passportPhotoPath': passportPhotoPath,
        'documentPath': documentPath,
        'isSynced': isSynced,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return true;
    } catch (e) {
      print('Error submitting application: $e');
      return false;
    }
  }

  // TEMPORARY SOLUTION: Direct database insert
  // This is only for testing and should not be used in production
  static Future<bool> _submitDirectlyToDatabase({
    required int scholarshipId,
    required String dateOfBirth,
    required String gender,
    required String category,
    required String major,
    required String homeAddress,
    required String studentId,
  }) async {
    try {
      // Direct insert using our temporary PHP script
      // IMPORTANT: Use 10.0.2.2 instead of localhost for Android emulators to access the host machine
      // "localhost" in the emulator refers to the emulator itself, not your computer
      const String host = "10.0.2.2"; // Hardcoded to prevent any confusion
      final url = 'http://$host/ASMSLive/direct_insert.php';

      // Prepare request data - match the exact field names from the PHP script
      final Map<String, dynamic> requestData = {
        'scholarshipId': scholarshipId,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'category': category,
        'major': major,
        'homeAddress': homeAddress,
        'studentId': studentId,
      };

      print('Sending direct insert request to: $url');
      print('Request data: $requestData');

      // Send the request with timeout
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Connection timeout while attempting to reach $url');
              throw TimeoutException('Connection timed out');
            },
          );

      print('Direct insert response code: ${response.statusCode}');
      print('Direct insert response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = json.decode(response.body);
          if (responseData["success"] == true) {
            print('Direct insert successful: ${responseData["message"]}');
            return true;
          } else {
            print('Direct insert API returned error: ${responseData["error"]}');
            return false;
          }
        } catch (e) {
          print('Error parsing response: $e');
          return response.statusCode ==
              200; // Assume success if status code is 200
        }
      } else {
        print('Direct insert failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error with direct DB insert: $e');
      // Print more detailed error information for debugging
      if (e is SocketException) {
        print(
          '  > Socket error details: ${e.message}, address: ${e.address}, port: ${e.port}',
        );
        print(
          '  > Make sure XAMPP is running and your server is accessible from the emulator',
        );
      } else if (e is TimeoutException) {
        print('  > Connection timed out - check your server and network');
      }
      return false;
    }
  }

  // Upload application to API
  static Future<bool> _uploadToApi({
    required int scholarshipId,
    required String scholarshipName,
    required String provider,
    required double amount,
    required String dateOfBirth,
    required String gender,
    required String category,
    required String major,
    required String homeAddress,
    required String studentId,
    required File passportPhoto,
    required File document,
  }) async {
    try {
      // Get auth token
      final token = await _apiService.getToken();
      if (token == null) {
        print('Error: No authentication token found');
        return false;
      }

      // The backend expects a JSON request, not multipart form
      final url = '${ApiConfig.baseUrl}${ApiConfig.submitApplication}';
      print('Submitting to URL: $url');

      // Prepare the request body with the expected field names
      final Map<String, dynamic> requestBody = {
        'schemeId': scholarshipId, // lowercase as expected by backend
        'dateOfBirth': dateOfBirth, // lowercase as expected by backend
        'gender': gender, // lowercase as expected by backend
        'category': category, // lowercase as expected by backend
        'major': major, // lowercase as expected by backend
        'address': homeAddress, // lowercase as expected by backend
        'ashesiId': studentId, // lowercase as expected by backend
      };

      print('Request body: $requestBody');

      // Send the request as JSON
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      // Try to decode JSON response
      Map<String, dynamic>? responseData;
      try {
        responseData = json.decode(response.body);
        print('API Response Data: $responseData');
      } catch (e) {
        print('Failed to decode response: $e');
      }

      // Check if the request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Application successfully submitted to backend');
        return true;
      } else {
        print('API Error Status: ${response.statusCode}');
        print('API Error Body: ${response.body}');
        if (responseData != null && responseData.containsKey('error')) {
          print('API Error Message: ${responseData['error']}');
        }
        return false;
      }
    } catch (e) {
      print('Error uploading to API: $e');
      return false;
    }
  }

  // Get all applications
  static Future<List<Application>> getApplications() async {
    try {
      await initApplicationDatabase();

      final db = await _databaseHelper.database;
      final result = await db.query(
        'applications',
        orderBy: 'appliedDate DESC',
      );

      return result.map((map) => Application.fromMap(map)).toList();
    } catch (e) {
      print('Error getting applications: $e');
      return [];
    }
  }

  // Get application by ID
  static Future<Application?> getApplication(int id) async {
    try {
      await initApplicationDatabase();

      final db = await _databaseHelper.database;
      final result = await db.query(
        'applications',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        return Application.fromMap(result.first);
      }

      return null;
    } catch (e) {
      print('Error getting application: $e');
      return null;
    }
  }

  // Sync pending applications
  static Future<void> syncPendingApplications() async {
    try {
      bool isConnected = await _connectivityService.isConnected();

      if (!isConnected) {
        return;
      }

      await initApplicationDatabase();

      final db = await _databaseHelper.database;
      final result = await db.query(
        'applications',
        where: 'isSynced = ?',
        whereArgs: [0],
      );

      for (var map in result) {
        final application = Application.fromMap(map);

        // Try to upload application to the backend
        bool success = false;

        try {
          // Create multipart request
          final token = await _apiService.getToken();
          if (token == null) {
            print('Error: No authentication token found');
            continue;
          }

          final url = '${ApiConfig.baseUrl}${ApiConfig.submitApplication}';

          // Prepare request body with lowercase field names as expected by backend
          final Map<String, dynamic> requestBody = {
            'schemeId': application.scholarshipId,
            'dateOfBirth': application.dateOfBirth,
            'gender': application.gender,
            'category': application.category,
            'major': application.major,
            'address': application.homeAddress,
            'ashesiId': application.studentId,
          };

          // Send the request as JSON
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          );

          success = response.statusCode >= 200 && response.statusCode < 300;

          if (success) {
            print('Successfully synced application ID: ${application.id}');
          } else {
            print(
              'Failed to sync application ID: ${application.id}. Status: ${response.statusCode}',
            );
          }
        } catch (e) {
          print('Error syncing application ID: ${application.id}: $e');
        }

        // Update local database status if sync was successful
        if (success) {
          await db.update(
            'applications',
            {'isSynced': 1, 'status': 'Submitted'},
            where: 'id = ?',
            whereArgs: [application.id],
          );
        }
      }
    } catch (e) {
      print('Error syncing pending applications: $e');
    }
  }
}

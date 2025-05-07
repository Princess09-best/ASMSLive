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
import '../services/notification_service.dart';

// Class to hold application submission result
class ApplicationSubmissionResult {
  final bool success;
  final String? message;
  final String? applicationNumber;

  ApplicationSubmissionResult(
      {required this.success, this.message, this.applicationNumber});
}

class ApplicationService {
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static final Uuid _uuid = Uuid();
  static final ApiService _apiService = ApiService();
  static final AuthService _authService = AuthService();

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
        applicationNumber TEXT,
        isSynced INTEGER NOT NULL,
        userId INTEGER
      )
      ''');
    } else {
      // Check if applicationNumber column exists, add it if it doesn't
      final columns = await db.rawQuery("PRAGMA table_info(applications)");
      bool hasApplicationNumber = false;
      bool hasUserId = false;

      for (var col in columns) {
        if (col['name'] == 'applicationNumber') {
          hasApplicationNumber = true;
        }
        if (col['name'] == 'userId') {
          hasUserId = true;
        }
      }

      // Add applicationNumber column if it doesn't exist
      if (!hasApplicationNumber) {
        await db.execute(
            'ALTER TABLE applications ADD COLUMN applicationNumber TEXT');
        print('Added applicationNumber column to applications table');
      }

      // Add userId column if it doesn't exist
      if (!hasUserId) {
        await db.execute('ALTER TABLE applications ADD COLUMN userId INTEGER');
        print('Added userId column to applications table');
      }
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

  // Submit application - enhanced version that returns result with message
  static Future<ApplicationSubmissionResult> submitApplicationWithResult({
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
    int? userId,
  }) async {
    try {
      // If userId is not provided, try to get it from the auth service
      if (userId == null) {
        final currentUser = await _authService.getCurrentUser();
        userId = currentUser?.id;
      }

      // Validate document file type
      if (!isValidDocumentType(document)) {
        print(
          'Invalid document type. Only PDF, DOC, or DOCX files are allowed',
        );
        return ApplicationSubmissionResult(
          success: false,
          message:
              'Invalid document type. Only PDF, DOC, or DOCX files are allowed',
        );
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
      String? resultMessage;
      String? applicationNumber;

      if (isConnected) {
        // Try uploading to the API
        final apiResult = await _uploadToApiWithResult(
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
          userId: userId,
        );

        if (apiResult.success) {
          resultMessage = apiResult.message;
          applicationNumber = apiResult.applicationNumber;
          isSynced = 1;
        } else {
          // API upload failed, try direct database insertion
          print("API upload failed, trying direct DB injection as backup...");
          try {
            final directResult = await _submitDirectlyToDatabaseWithResult(
              scholarshipId: scholarshipId,
              dateOfBirth: dateOfBirth,
              gender: gender,
              category: category,
              major: major,
              homeAddress: homeAddress,
              studentId: studentId,
              userId: userId,
              passportPhoto: passportPhoto,
              document: document,
            );

            if (directResult.success) {
              resultMessage = directResult.message;
              applicationNumber = directResult.applicationNumber;
              isSynced = 1;
              print("Direct DB injection as backup was successful");
            } else {
              print("Direct DB injection failed");
            }
          } catch (e) {
            print("Direct DB injection failed: $e");
          }
        }
      }

      // Create a unique ID for the application
      final id = now.millisecondsSinceEpoch;

      // Save to local database
      final db = await _databaseHelper.database;
      await db.insert(
          'applications',
          {
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
            'applicationNumber': applicationNumber,
            'isSynced': isSynced,
            'userId': userId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Default message if none was provided
      if (resultMessage == null) {
        resultMessage = 'Your application has been saved ' +
            (isSynced == 1
                ? 'and submitted successfully.'
                : 'locally and will be submitted when you have internet connection.');
      }

      return ApplicationSubmissionResult(
        success: true,
        message: resultMessage,
        applicationNumber: applicationNumber,
      );
    } catch (e) {
      print('Error submitting application: $e');
      return ApplicationSubmissionResult(
        success: false,
        message: 'Error submitting application: $e',
      );
    }
  }

  // Submit application - original version for backward compatibility
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
    int? userId,
  }) async {
    final result = await submitApplicationWithResult(
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
      userId: userId,
    );

    return result.success;
  }

  // TEMPORARY SOLUTION: Direct database insert with result
  static Future<ApplicationSubmissionResult>
      _submitDirectlyToDatabaseWithResult({
    required int scholarshipId,
    required String dateOfBirth,
    required String gender,
    required String category,
    required String major,
    required String homeAddress,
    required String studentId,
    int? userId,
    File? passportPhoto,
    File? document,
  }) async {
    try {
      // If userId is null, try to get it from auth service
      if (userId == null) {
        final currentUser = await _authService.getCurrentUser();
        userId = currentUser?.id ?? 1; // Fallback to 1 if all else fails
      }

      // Upload passport photo if provided
      String profilePic = 'default_profile.jpg';
      if (passportPhoto != null) {
        try {
          const String host =
              "172.16.5.8"; // Hardcoded to prevent any confusion
          final profileUploadUrl =
              'http://$host/ASMSLive/mobile_asms/file_upload.php';

          // Create multipart request for profile photo
          var profileRequest =
              http.MultipartRequest('POST', Uri.parse(profileUploadUrl));

          // Add file
          var profileStream = http.ByteStream(passportPhoto.openRead());
          var profileLength = await passportPhoto.length();
          var profileMultipartFile = http.MultipartFile(
              'profilePic', profileStream, profileLength,
              filename: passportPhoto.path.split('/').last);

          profileRequest.files.add(profileMultipartFile);
          profileRequest.fields['fileType'] = 'profile';

          // Send the request
          var profileResponse = await profileRequest.send();
          var profileResponseData =
              await http.Response.fromStream(profileResponse);

          print('Profile pic upload response: ${profileResponseData.body}');

          if (profileResponse.statusCode == 200) {
            final responseJson = json.decode(profileResponseData.body);
            if (responseJson['success'] == true) {
              profilePic = responseJson['filename'];
              print('Profile pic uploaded successfully: $profilePic');
            }
          } else {
            print('Failed to upload profile pic: ${profileResponseData.body}');
          }
        } catch (e) {
          print('Error uploading profile pic: $e');
          // Continue with default profile pic
        }
      }

      // Upload document if provided
      String docReq = 'default_document.pdf';
      if (document != null) {
        try {
          const String host =
              "172.16.5.8"; // Hardcoded to prevent any confusion
          final docUploadUrl =
              'http://$host/ASMSLive/mobile_asms/file_upload.php';

          // Create multipart request for document
          var docRequest =
              http.MultipartRequest('POST', Uri.parse(docUploadUrl));

          // Add file
          var docStream = http.ByteStream(document.openRead());
          var docLength = await document.length();
          var docMultipartFile = http.MultipartFile(
              'document', docStream, docLength,
              filename: document.path.split('/').last);

          docRequest.files.add(docMultipartFile);
          docRequest.fields['fileType'] = 'document';

          // Send the request
          var docResponse = await docRequest.send();
          var docResponseData = await http.Response.fromStream(docResponse);

          print('Document upload response: ${docResponseData.body}');

          if (docResponse.statusCode == 200) {
            final responseJson = json.decode(docResponseData.body);
            if (responseJson['success'] == true) {
              docReq = responseJson['filename'];
              print('Document uploaded successfully: $docReq');
            }
          } else {
            print('Failed to upload document: ${docResponseData.body}');
          }
        } catch (e) {
          print('Error uploading document: $e');
          // Continue with default document
        }
      }

      // Direct insert using our temporary PHP script
      const String host = "172.16.5.8"; // Hardcoded to prevent any confusion
      final url = 'http://$host/ASMSLive/mobile_asms/direct_insert.php';

      // Prepare request data - match the exact field names from the PHP script
      final Map<String, dynamic> requestData = {
        'schemeId': scholarshipId,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'category': category,
        'major': major,
        'address': homeAddress,
        'ashesiId': studentId,
        'pic': profilePic,
        'doc': docReq,
        'userId': userId,
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

            // Get application number from response if available
            String? appNumber;
            if (responseData.containsKey("applicationNumber")) {
              appNumber = responseData["applicationNumber"].toString();
            }

            return ApplicationSubmissionResult(
              success: true,
              message: responseData["message"],
              applicationNumber: appNumber,
            );
          } else {
            print('Direct insert API returned error: ${responseData["error"]}');
            return ApplicationSubmissionResult(
              success: false,
              message: responseData["error"] ?? "Unknown error",
            );
          }
        } catch (e) {
          print('Error parsing response: $e');
          return ApplicationSubmissionResult(
            success: response.statusCode == 200,
            message: "Application submitted",
          );
        }
      } else {
        print('Direct insert failed with status code: ${response.statusCode}');
        return ApplicationSubmissionResult(
          success: false,
          message: "Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Error with direct DB insert: $e');
      String errorMessage = "Connection error";

      // More detailed error information for debugging
      if (e is SocketException) {
        print(
          '  > Socket error details: ${e.message}, address: ${e.address}, port: ${e.port}',
        );
        print(
          '  > Make sure XAMPP is running and your server is accessible from the emulator',
        );
        errorMessage = "Server connection error: ${e.message}";
      } else if (e is TimeoutException) {
        print('  > Connection timed out - check your server and network');
        errorMessage = "Connection timed out";
      }

      return ApplicationSubmissionResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  // TEMPORARY SOLUTION: Direct database insert - original version
  static Future<bool> _submitDirectlyToDatabase({
    required int scholarshipId,
    required String dateOfBirth,
    required String gender,
    required String category,
    required String major,
    required String homeAddress,
    required String studentId,
    int? userId,
  }) async {
    final result = await _submitDirectlyToDatabaseWithResult(
      scholarshipId: scholarshipId,
      dateOfBirth: dateOfBirth,
      gender: gender,
      category: category,
      major: major,
      homeAddress: homeAddress,
      studentId: studentId,
      userId: userId,
    );

    return result.success;
  }

  // Upload application to API with result
  static Future<ApplicationSubmissionResult> _uploadToApiWithResult({
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
    int? userId,
  }) async {
    try {
      // If userId is null, try to get it from auth service
      if (userId == null) {
        final currentUser = await _authService.getCurrentUser();
        userId = currentUser?.id ?? 1; // Fallback to 1 if all else fails
      }

      // Get auth token
      final token = await _apiService.getToken();
      if (token == null) {
        print('Error: No authentication token found');
        return ApplicationSubmissionResult(
          success: false,
          message: "Authentication failed",
        );
      }

      // First, upload the passport photo
      print('Uploading passport photo...');
      String profilePic = 'default_profile.jpg';
      try {
        const String host = "172.16.5.8"; // Hardcoded to prevent any confusion
        final profileUploadUrl =
            'http://$host/ASMSLive/mobile_asms/file_upload.php';

        // Create multipart request for profile photo
        var profileRequest =
            http.MultipartRequest('POST', Uri.parse(profileUploadUrl));

        // Add file
        var profileStream = http.ByteStream(passportPhoto.openRead());
        var profileLength = await passportPhoto.length();
        var profileMultipartFile = http.MultipartFile(
            'profilePic', profileStream, profileLength,
            filename: passportPhoto.path.split('/').last);

        profileRequest.files.add(profileMultipartFile);
        profileRequest.fields['fileType'] = 'profile';

        // Send the request
        var profileResponse = await profileRequest.send();
        var profileResponseData =
            await http.Response.fromStream(profileResponse);

        print('Profile pic upload response: ${profileResponseData.body}');

        if (profileResponse.statusCode == 200) {
          final responseJson = json.decode(profileResponseData.body);
          if (responseJson['success'] == true) {
            profilePic = responseJson['filename'];
            print('Profile pic uploaded successfully: $profilePic');
          }
        } else {
          print('Failed to upload profile pic: ${profileResponseData.body}');
        }
      } catch (e) {
        print('Error uploading profile pic: $e');
        // Continue with default profile pic
      }

      // Then, upload the document
      print('Uploading document...');
      String docReq = 'default_document.pdf';
      try {
        const String host = "172.16.5.8"; // Hardcoded to prevent any confusion
        final docUploadUrl =
            'http://$host/ASMSLive/mobile_asms/file_upload.php';

        // Create multipart request for document
        var docRequest = http.MultipartRequest('POST', Uri.parse(docUploadUrl));

        // Add file
        var docStream = http.ByteStream(document.openRead());
        var docLength = await document.length();
        var docMultipartFile = http.MultipartFile(
            'document', docStream, docLength,
            filename: document.path.split('/').last);

        docRequest.files.add(docMultipartFile);
        docRequest.fields['fileType'] = 'document';

        // Send the request
        var docResponse = await docRequest.send();
        var docResponseData = await http.Response.fromStream(docResponse);

        print('Document upload response: ${docResponseData.body}');

        if (docResponse.statusCode == 200) {
          final responseJson = json.decode(docResponseData.body);
          if (responseJson['success'] == true) {
            docReq = responseJson['filename'];
            print('Document uploaded successfully: $docReq');
          }
        } else {
          print('Failed to upload document: ${docResponseData.body}');
        }
      } catch (e) {
        print('Error uploading document: $e');
        // Continue with default document
      }

      // Now submit the application with the uploaded file names
      final url = '${ApiConfig.baseUrl}${ApiConfig.submitApplication}';
      print('Submitting application to URL: $url');

      // Prepare the request body with the expected field names
      final Map<String, dynamic> requestBody = {
        'schemeId': scholarshipId, // lowercase as expected by backend
        'dateOfBirth': dateOfBirth, // lowercase as expected by backend
        'gender': gender, // lowercase as expected by backend
        'category': category, // lowercase as expected by backend
        'major': major, // lowercase as expected by backend
        'address': homeAddress, // lowercase as expected by backend
        'ashesiId': studentId, // lowercase as expected by backend
        'userId': userId, // Add user ID
        'pic': profilePic, // Add the uploaded profile pic filename
        'doc': docReq, // Add the uploaded document filename
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

        String? appNumber;
        if (responseData != null &&
            responseData.containsKey("applicationNumber")) {
          appNumber = responseData["applicationNumber"].toString();
        }

        String message =
            responseData != null && responseData.containsKey("message")
                ? responseData["message"]
                : "Application successfully submitted";

        return ApplicationSubmissionResult(
          success: true,
          message: message,
          applicationNumber: appNumber,
        );
      } else {
        print('API Error Status: ${response.statusCode}');
        print('API Error Body: ${response.body}');

        String errorMessage = "Server error";
        if (responseData != null && responseData.containsKey('error')) {
          errorMessage = responseData['error'];
          print('API Error Message: $errorMessage');
        }

        return ApplicationSubmissionResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      print('Error uploading to API: $e');
      return ApplicationSubmissionResult(
        success: false,
        message: "Error: $e",
      );
    }
  }

  // Upload application to API - original version
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
    final result = await _uploadToApiWithResult(
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

    return result.success;
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
  static Future<bool> syncPendingApplications({int? userId}) async {
    try {
      bool isConnected = await _connectivityService.isConnected();

      if (!isConnected) {
        print('Not connected to the internet. Skipping sync.');
        return false;
      }

      print('Starting to sync pending applications...');
      await initApplicationDatabase();

      final db = await _databaseHelper.database;

      // Build query based on whether userId is provided
      String whereClause = 'isSynced = ?';
      List<dynamic> whereArgs = [0];

      if (userId != null) {
        whereClause += ' AND userId = ?';
        whereArgs.add(userId);
        print('Filtering pending applications for user ID: $userId');
      } else {
        print('Syncing all pending applications regardless of user');
      }

      final result = await db.query(
        'applications',
        where: whereClause,
        whereArgs: whereArgs,
      );

      print('Found ${result.length} pending applications to sync');

      if (result.isEmpty) {
        print('No pending applications to sync');
        return false;
      }

      // Initialize notification service
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Keep track of successful syncs for batch notification
      List<String> syncedScholarshipNames = [];
      bool anySuccess = false;

      for (var map in result) {
        final application = Application.fromMap(map);
        print('Attempting to sync application ID: ${application.id}');

        // Try to upload application to the backend
        bool success = false;

        try {
          // First try API method
          print('Trying API submission for application ID: ${application.id}');

          // Load the files from local storage if they exist
          File? passportPhotoFile;
          File? documentFile;

          try {
            if (application.passportPhotoPath.isNotEmpty) {
              passportPhotoFile = File(application.passportPhotoPath);
              if (!await passportPhotoFile.exists()) {
                print(
                    'Passport photo file does not exist: ${application.passportPhotoPath}');
                passportPhotoFile = null;
              }
            }

            if (application.documentPath.isNotEmpty) {
              documentFile = File(application.documentPath);
              if (!await documentFile.exists()) {
                print(
                    'Document file does not exist: ${application.documentPath}');
                documentFile = null;
              }
            }
          } catch (e) {
            print('Error loading files: $e');
            // Continue without files if there's an error
          }

          // Create multipart request
          final token = await _apiService.getToken();
          if (token == null) {
            print('Error: No authentication token found');
            // Continue to direct DB method
          } else {
            final url = '${ApiConfig.baseUrl}${ApiConfig.submitApplication}';

            // First try to upload the files using our file upload endpoint
            String profilePic = 'default_profile.jpg';
            String docReq = 'default_document.pdf';

            // Upload passport photo if available
            if (passportPhotoFile != null) {
              try {
                const String host =
                    "172.16.5.8"; // Hardcoded to prevent any confusion
                final profileUploadUrl =
                    'http://$host/ASMSLive/mobile_asms/file_upload.php';

                var profileRequest =
                    http.MultipartRequest('POST', Uri.parse(profileUploadUrl));

                var profileStream =
                    http.ByteStream(passportPhotoFile.openRead());
                var profileLength = await passportPhotoFile.length();
                var profileMultipartFile = http.MultipartFile(
                    'profilePic', profileStream, profileLength,
                    filename: passportPhotoFile.path.split('/').last);

                profileRequest.files.add(profileMultipartFile);
                profileRequest.fields['fileType'] = 'profile';

                var profileResponse = await profileRequest.send();
                var profileResponseData =
                    await http.Response.fromStream(profileResponse);

                if (profileResponse.statusCode == 200) {
                  final responseJson = json.decode(profileResponseData.body);
                  if (responseJson['success'] == true) {
                    profilePic = responseJson['filename'];
                    print('Profile pic uploaded successfully: $profilePic');
                  }
                }
              } catch (e) {
                print('Error uploading profile pic: $e');
              }
            }

            // Upload document if available
            if (documentFile != null) {
              try {
                const String host =
                    "172.16.5.8"; // Hardcoded to prevent any confusion
                final docUploadUrl =
                    'http://$host/ASMSLive/mobile_asms/file_upload.php';

                var docRequest =
                    http.MultipartRequest('POST', Uri.parse(docUploadUrl));

                var docStream = http.ByteStream(documentFile.openRead());
                var docLength = await documentFile.length();
                var docMultipartFile = http.MultipartFile(
                    'document', docStream, docLength,
                    filename: documentFile.path.split('/').last);

                docRequest.files.add(docMultipartFile);
                docRequest.fields['fileType'] = 'document';

                var docResponse = await docRequest.send();
                var docResponseData =
                    await http.Response.fromStream(docResponse);

                if (docResponse.statusCode == 200) {
                  final responseJson = json.decode(docResponseData.body);
                  if (responseJson['success'] == true) {
                    docReq = responseJson['filename'];
                    print('Document uploaded successfully: $docReq');
                  }
                }
              } catch (e) {
                print('Error uploading document: $e');
              }
            }

            // Prepare request body with lowercase field names as expected by backend
            final Map<String, dynamic> requestBody = {
              'schemeId': application.scholarshipId,
              'dateOfBirth': application.dateOfBirth,
              'gender': application.gender,
              'category': application.category,
              'major': application.major,
              'address': application.homeAddress,
              'ashesiId': application.studentId,
              'userId': application.userId,
              'pic': profilePic,
              'doc': docReq,
            };

            // Send the request as JSON
            print('Sending API request to: $url');
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
              print(
                  'Successfully synced application ID: ${application.id} via API');
            } else {
              print(
                'Failed to sync application ID: ${application.id} via API. Status: ${response.statusCode}',
              );
            }
          }

          // If API method fails, try direct database insertion
          if (!success) {
            print('API submission failed, trying direct database insertion...');
            try {
              final result = await _submitDirectlyToDatabaseWithResult(
                scholarshipId: application.scholarshipId,
                dateOfBirth: application.dateOfBirth,
                gender: application.gender,
                category: application.category,
                major: application.major,
                homeAddress: application.homeAddress,
                studentId: application.studentId,
                userId: application.userId,
                passportPhoto: passportPhotoFile,
                document: documentFile,
              );

              success = result.success;
              if (success) {
                print(
                    'Successfully synced application ID: ${application.id} via direct DB insertion');
              } else {
                print(
                    'Failed to sync application ID: ${application.id} via direct DB insertion');
              }
            } catch (e) {
              print(
                  'Error with direct DB insert for application ID: ${application.id}: $e');
            }
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
          print(
              'Updated local database for application ID: ${application.id} - marked as synced');

          // Track successful sync for notification
          syncedScholarshipNames.add(application.scholarshipName);
          anySuccess = true;

          // Show individual notification if desired
          // await notificationService.showApplicationStatusNotification(
          //   applicationId: application.id,
          //   scholarshipName: application.scholarshipName,
          //   status: 'submitted',
          // );
        } else {
          print(
              'Failed to sync application ID: ${application.id} - remains pending');
        }
      }

      // Show a summary notification if any applications were successfully synced
      if (anySuccess) {
        final uniqueScholarshipCount = syncedScholarshipNames.toSet().length;
        String notificationTitle = 'Applications Synced';
        String notificationBody;

        if (uniqueScholarshipCount == 1) {
          notificationBody =
              'Your application for ${syncedScholarshipNames[0]} has been successfully submitted.';
        } else {
          notificationBody =
              '$uniqueScholarshipCount scholarship applications have been successfully submitted.';
        }

        await notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: notificationTitle,
          body: notificationBody,
          payload: 'sync_completed',
        );
      }

      print('Finished syncing pending applications');
      return anySuccess;
    } catch (e) {
      print('Error syncing pending applications: $e');
      return false;
    }
  }

  // Get applications by user ID
  static Future<List<Application>> getApplicationsByUserId(int? userId) async {
    try {
      await initApplicationDatabase();

      if (userId == null) {
        print(
            'Warning: Null userId in getApplicationsByUserId, returning empty list');
        return [];
      }

      final db = await _databaseHelper.database;
      final result = await db.query(
        'applications',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'appliedDate DESC',
      );

      print('Found ${result.length} applications for user ID: $userId');
      return result.map((map) => Application.fromMap(map)).toList();
    } catch (e) {
      print('Error getting applications by user ID: $e');
      return [];
    }
  }
}

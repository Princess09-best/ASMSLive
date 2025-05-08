import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';

class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get the stored auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  // Set the auth token
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
  }

  // Remove the auth token (logout)
  Future<void> removeToken() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
  }

  // Helper method to build URL
  String _buildUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  // Add auth header to request
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseData = json.decode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return responseData;
    } else if (statusCode == 401) {
      // Token expired or invalid
      throw Exception('Unauthorized: ${responseData['message']}');
    } else {
      throw Exception('API Error: ${responseData['message']}');
    }
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print('API GET: $url');
      print('Raw response: ${response.body}');
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Failed to update data: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  // Upload files with form data
  Future<dynamic> uploadFile(String endpoint, File file,
      {Map<String, String>? fields}) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    // Remove content-type header as it will be set by multipart request
    headers.remove('Content-Type');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add other fields if provided
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}

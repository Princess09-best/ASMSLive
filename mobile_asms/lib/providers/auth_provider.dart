import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Check if user is already logged in
  Future<bool> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // For the legacy PHP backend, we need to read the stored user data
        _currentUser = await _authService.getCurrentUser();

        // If we have a username but need to refresh from server
        if (_currentUser != null && _currentUser!.email.isNotEmpty) {
          try {
            // Try to refresh user data from server
            final refreshedUser =
                await _fetchUserDataFromServer(_currentUser!.email);
            if (refreshedUser != null) {
              _currentUser = refreshedUser;
              await _authService.storeUserData(refreshedUser);
            }
          } catch (e) {
            // Ignore refresh errors, use stored data
            print('Error refreshing user data: $e');
          }
        }
      }
      _isLoading = false;
      notifyListeners();
      return isLoggedIn;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fetch user data from the PHP backend
  Future<User?> _fetchUserDataFromServer(String username) async {
    try {
      // This function would typically use your API service
      // But for the legacy PHP backend, we need to use direct HTTP
      final userDataUrl =
          Uri.parse('http://172.16.5.8/ASMSLive/users/get_user_data.php');
      final request = await HttpClient().postUrl(userDataUrl);
      request.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(Uri(queryParameters: {
        'username': username,
      }).query);

      final userDataResponse = await request.close();
      final userDataBody =
          await userDataResponse.transform(const Utf8Decoder()).join();

      // Attempt to parse user data
      final userData = jsonDecode(userDataBody);
      if (userData != null && userData['success'] == true) {
        // Create user model
        return User(
          id: userData['id'],
          fullName: userData['fullName'],
          email: userData['email'],
          mobileNumber: userData['mobileNumber'],
        );
      }
    } catch (e) {
      print('Error fetching user data from server: $e');
    }
    return null;
  }

  // Set current user directly (for legacy login)
  void setUser(User user) {
    _currentUser = user;
    // Store user in secure storage for persistence
    _authService.storeUserData(user);
    notifyListeners();
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register(String fullName, String email, String password,
      String mobileNumber) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser =
          await _authService.register(fullName, email, password, mobileNumber);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(updatedUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Biometric authentication
  Future<bool> authenticateWithBiometrics() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated) {
        _currentUser = await _authService.getCurrentUser();
      }
      _isLoading = false;
      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  // Enable or disable biometric login
  Future<void> setBiometricEnabled(bool enabled) async {
    await _authService.setBiometricEnabled(enabled);
    notifyListeners();
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    return await _authService.isBiometricEnabled();
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

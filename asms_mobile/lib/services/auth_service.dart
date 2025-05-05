import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {'email': email, 'password': password},
      );

      // Store the token
      await _apiService.setToken(response['data']['token']);

      // Save user data
      final user = User.fromJson(response['data']['user']);
      await _storeUserData(user);

      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register a new user
  Future<User> register(String fullName, String email, String password,
      String mobileNumber) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        {
          'fullName': fullName,
          'email': email,
          'password': password,
          'mobileNumber': mobileNumber,
        },
      );

      // Store the token
      await _apiService.setToken(response['data']['token']);

      // Save user data
      final user = User.fromJson(response['data']['user']);
      await _storeUserData(user);

      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout API
      await _apiService.post(ApiConfig.logout, {});
    } catch (e) {
      // Even if API call fails, we still want to clear local data
      print('Logout API call failed: $e');
    } finally {
      // Clear token and user data
      await _apiService.removeToken();
      await _secureStorage.delete(key: AppConstants.userInfoKey);

      // Clear biometric settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.biometricEnabledKey, false);
    }
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    final userJson = await _secureStorage.read(key: AppConstants.userInfoKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Update user profile
  Future<User> updateProfile(User updatedUser) async {
    try {
      final response = await _apiService.put(
        ApiConfig.updateProfile,
        updatedUser.toJson(),
      );

      // Save updated user data
      final user = User.fromJson(response['data']['user']);
      await _storeUserData(user);

      return user;
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Store user data securely
  Future<void> _storeUserData(User user) async {
    await _secureStorage.write(
      key: AppConstants.userInfoKey,
      value: jsonEncode(user.toJson()),
    );
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  // Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: AppConstants.biometricReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Enable or disable biometric login
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.biometricEnabledKey, enabled);
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.biometricEnabledKey) ?? false;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }
}

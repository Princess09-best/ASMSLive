import 'package:flutter/material.dart';
import '../models/scholarship_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../config/api_config.dart';

class ScholarshipProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  
  List<Scholarship> _scholarships = [];
  List<Scholarship> _nearbyScholarships = [];
  Scholarship? _selectedScholarship;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasMoreScholarships = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  
  // Getters
  List<Scholarship> get scholarships => _scholarships;
  List<Scholarship> get nearbyScholarships => _nearbyScholarships;
  Scholarship? get selectedScholarship => _selectedScholarship;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMoreScholarships => _hasMoreScholarships;
  
  // Fetch all scholarships with pagination
  Future<void> fetchScholarships({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreScholarships = true;
    }
    
    if (_isLoading || (!_hasMoreScholarships && !refresh)) {
      return;
    }
    
    _isLoading = true;
    if (refresh) {
      _scholarships = [];
    }
    notifyListeners();
    
    try {
      final response = await _apiService.get(
        '${ApiConfig.scholarships}?page=$_currentPage&limit=$_pageSize',
      );
      
      final List<dynamic> scholarshipData = response['data']['scholarships'];
      final List<Scholarship> newScholarships = scholarshipData
        .map((data) => Scholarship.fromJson(data))
        .toList();
      
      _scholarships.addAll(newScholarships);
      _hasMoreScholarships = newScholarships.length == _pageSize;
      _currentPage++;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get scholarship details
  Future<void> getScholarshipDetails(int scholarshipId) async {
    _isLoading = true;
    _selectedScholarship = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get(
        '${ApiConfig.scholarshipDetails}/$scholarshipId',
      );
      
      _selectedScholarship = Scholarship.fromJson(response['data']);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search scholarships by keyword
  Future<List<Scholarship>> searchScholarships(String keyword) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get(
        '${ApiConfig.scholarships}/search?keyword=$keyword',
      );
      
      final List<dynamic> scholarshipData = response['data']['scholarships'];
      final List<Scholarship> searchResults = scholarshipData
        .map((data) => Scholarship.fromJson(data))
        .toList();
      
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return searchResults;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // Filter scholarships
  List<Scholarship> filterScholarships({
    double? minAmount,
    double? maxAmount,
    DateTime? deadlineAfter,
    String? status,
  }) {
    return _scholarships.where((scholarship) {
      bool passesFilter = true;
      
      if (minAmount != null) {
        passesFilter = passesFilter && scholarship.amount >= minAmount;
      }
      
      if (maxAmount != null) {
        passesFilter = passesFilter && scholarship.amount <= maxAmount;
      }
      
      if (deadlineAfter != null) {
        passesFilter = passesFilter && scholarship.applicationDeadline.isAfter(deadlineAfter);
      }
      
      if (status != null) {
        passesFilter = passesFilter && scholarship.status == status;
      }
      
      return passesFilter;
    }).toList();
  }
  
  // Get nearby scholarships
  Future<void> fetchNearbyScholarships({double radiusInKm = 50.0}) async {
    _isLoading = true;
    _nearbyScholarships = [];
    notifyListeners();
    
    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();
      
      // Prepare scholarship data for location service
      List<Map<String, dynamic>> scholarshipDataList = _scholarships
        .map((scholarship) => {
          'id': scholarship.id,
          'name': scholarship.name,
          'latitude': scholarship.latitude,
          'longitude': scholarship.longitude,
        })
        .toList();
      
      // Find nearby scholarships
      final nearbyScholarshipData = await _locationService.findNearbyScholarships(
        scholarshipDataList,
        radiusInKm: radiusInKm,
      );
      
      // Map nearby scholarship IDs
      final nearbyScholarshipIds = nearbyScholarshipData
        .map((data) => data['id'] as int)
        .toSet();
      
      // Filter scholarships by nearby IDs
      _nearbyScholarships = _scholarships
        .where((scholarship) => nearbyScholarshipIds.contains(scholarship.id))
        .toList();
      
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set selected scholarship
  void setSelectedScholarship(Scholarship scholarship) {
    _selectedScholarship = scholarship;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  // Clear selected scholarship
  void clearSelectedScholarship() {
    _selectedScholarship = null;
    notifyListeners();
  }
} 
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // Get current position with high accuracy
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        throw Exception('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // Permissions are granted, get position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  // Get last known position (faster but may be less accurate)
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }
  
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  // Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  // Calculate distance between two points in kilometers
  double calculateDistance(
    double startLatitude, 
    double startLongitude, 
    double endLatitude, 
    double endLongitude
  ) {
    return Geolocator.distanceBetween(
      startLatitude, 
      startLongitude, 
      endLatitude, 
      endLongitude
    ) / 1000; // Convert meters to kilometers
  }
  
  // Find nearby scholarships based on a list and current location
  Future<List<Map<String, dynamic>>> findNearbyScholarships(
    List<Map<String, dynamic>> scholarships,
    {double radiusInKm = 50.0}
  ) async {
    try {
      final currentPosition = await getCurrentPosition();
      
      return scholarships.where((scholarship) {
        // Check if scholarship has location data
        if (scholarship['latitude'] == null || scholarship['longitude'] == null) {
          return false;
        }
        
        // Calculate distance
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          scholarship['latitude'], 
          scholarship['longitude']
        );
        
        // Add distance to scholarship data
        scholarship['distance'] = distance;
        
        // Return true if within radius
        return distance <= radiusInKm;
      }).toList()
        // Sort by distance
        ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    } catch (e) {
      print('Error finding nearby scholarships: $e');
      return [];
    }
  }
  
  // Open maps app with the given coordinates
  Future<void> openMapsWithLocation(double latitude, double longitude, String label) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      print('Error opening maps: $e');
      throw Exception('Failed to open maps: $e');
    }
  }
} 
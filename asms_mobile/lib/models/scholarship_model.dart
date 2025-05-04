import 'package:intl/intl.dart';

class Scholarship {
  final int id;
  final String name;
  final String description;
  final String provider;
  final double amount;
  final DateTime applicationDeadline;
  final List<String> requiredDocuments;
  final String? eligibilityCriteria;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String status; // active, inactive, closed
  final String? coverImage;

  Scholarship({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
    required this.amount,
    required this.applicationDeadline,
    required this.requiredDocuments,
    this.eligibilityCriteria,
    this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.coverImage,
  });

  // Factory constructor to create a Scholarship object from a JSON map
  factory Scholarship.fromJson(Map<String, dynamic> json) {
    return Scholarship(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      provider: json['provider'],
      amount: double.parse(json['amount'].toString()),
      applicationDeadline: DateTime.parse(json['applicationDeadline']),
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      eligibilityCriteria: json['eligibilityCriteria'],
      location: json['location'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      status: json['status'],
      coverImage: json['coverImage'],
    );
  }

  // Convert Scholarship object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'provider': provider,
      'amount': amount,
      'applicationDeadline': applicationDeadline.toIso8601String(),
      'requiredDocuments': requiredDocuments,
      'eligibilityCriteria': eligibilityCriteria,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'coverImage': coverImage,
    };
  }

  // Format the scholarship amount with currency symbol
  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }

  // Get formatted deadline date
  String get formattedDeadline {
    return DateFormat('MMMM dd, yyyy').format(applicationDeadline);
  }

  // Check if scholarship is still open for applications
  bool get isOpen {
    return status == 'active' && applicationDeadline.isAfter(DateTime.now());
  }

  // Calculate days remaining until deadline
  int get daysRemaining {
    return applicationDeadline.difference(DateTime.now()).inDays;
  }
} 
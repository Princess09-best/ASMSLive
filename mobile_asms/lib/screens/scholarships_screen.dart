import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../config/app_constants.dart';
import '../widgets/scholarship_card.dart';
import '../models/scholarship.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Scholarship> _scholarships = [];

  @override
  void initState() {
    super.initState();
    _fetchScholarships();
  }

  Future<void> _fetchScholarships() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Connect to the real API endpoint
      final uri = Uri.parse('http://10.0.2.2/ASMSLive/api/scholarships');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('scholarships')) {
          final scholarshipsList = data['scholarships'] as List;

          // Convert API response to Scholarship objects
          final scholarships = scholarshipsList.map((item) {
            // Make sure data types match our model
            return Scholarship(
              id: item['ID'] is String ? int.parse(item['ID']) : item['ID'],
              name: item['SchemeName'] ?? 'Unknown Scholarship',
              provider: item['Organization'] ?? 'Unknown Provider',
              amount: item['ScholarAmount'] is String
                  ? double.tryParse(item['ScholarAmount']) ?? 0.0
                  : (item['ScholarAmount'] ?? 0.0).toDouble(),
              deadline: item['LastDate'] ?? DateTime.now().toString(),
              location: item['Category'] ?? 'Ghana',
              distance: 0.0, // To be calculated later with geolocation
            );
          }).toList();

          setState(() {
            _scholarships = scholarships;
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load scholarships: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scholarships: $e';
        _isLoading = false;
      });

      // Fallback to sample data for testing when API fails
      _loadSampleData();
    }
  }

  // Add a method to load sample data as fallback
  void _loadSampleData() {
    final sampleData = [
      {
        'id': 1,
        'name': 'Engineering Excellence Scholarship',
        'provider': 'TechFoundation',
        'amount': 10000,
        'deadline': '2023-12-15',
        'location': 'Accra, Ghana',
        'distance': 0,
      },
      {
        'id': 2,
        'name': 'Future Leaders Scholarship',
        'provider': 'Global Education Fund',
        'amount': 5000,
        'deadline': '2023-11-30',
        'location': 'Accra, Ghana',
        'distance': 0,
      },
      {
        'id': 3,
        'name': 'Computer Science Innovation Grant',
        'provider': 'Digital Africa Initiative',
        'amount': 7500,
        'deadline': '2023-10-15',
        'location': 'Kumasi, Ghana',
        'distance': 0,
      },
      {
        'id': 4,
        'name': 'Women in STEM Scholarship',
        'provider': 'African Women\'s Foundation',
        'amount': 12000,
        'deadline': '2024-01-30',
        'location': 'Accra, Ghana',
        'distance': 0,
      },
      {
        'id': 5,
        'name': 'Entrepreneurship Development Fund',
        'provider': 'Ghana Business Council',
        'amount': 8000,
        'deadline': '2023-11-15',
        'location': 'Cape Coast, Ghana',
        'distance': 0,
      },
    ];

    setState(() {
      _scholarships =
          sampleData.map((data) => Scholarship.fromJson(data)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchScholarships,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchScholarships,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_scholarships.isEmpty) {
      return const Center(
        child: Text('No scholarships available at this time.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _scholarships.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final scholarship = _scholarships[index];
        return ScholarshipCard(
          id: scholarship.id,
          name: scholarship.name,
          provider: scholarship.provider,
          amount: scholarship.amount,
          deadline: scholarship.deadline,
          location: scholarship.location,
          distance: scholarship.distance,
        );
      },
    );
  }
}

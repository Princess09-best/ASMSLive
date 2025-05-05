import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../widgets/scholarship_card.dart';
import '../models/scholarship.dart';
import '../services/scholarship_service.dart';
import '../services/connectivity_service.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Scholarship> _scholarships = [];
  bool _isConnected = true;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _fetchScholarships();

    // Listen for connectivity changes
    _connectivityService.listenToConnectivityChanges((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _fetchScholarships() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use the ScholarshipService to get all scholarships (without limit)
      final scholarships = await ScholarshipService.getScholarships(limit: 50);

      setState(() {
        _scholarships = scholarships;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scholarships: $e';
        _isLoading = false;
      });
    }
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
        child: Column(
          children: [
            // Network status indicator
            if (!_isConnected)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade800),
                    const SizedBox(width: 8.0),
                    const Expanded(
                      child: Text(
                        'You are offline. Showing cached scholarships.',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
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

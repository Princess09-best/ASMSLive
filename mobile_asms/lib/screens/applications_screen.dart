import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../config/app_constants.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/connectivity_service.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _isLoading = true;
  List<Application> _applications = [];
  bool _isConnected = true;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadApplications();
    _syncPendingApplications();

    // Listen for connectivity changes
    _connectivityService.listenToConnectivityChanges((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        _syncPendingApplications();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    final applications = await ApplicationService.getApplications();

    setState(() {
      _applications = applications;
      _isLoading = false;
    });
  }

  Future<void> _syncPendingApplications() async {
    try {
      bool synced = await _connectivityService.syncIfConnected();
      if (synced) {
        // Reload applications to show updated status
        await _loadApplications();
      }
    } catch (e) {
      print('Error syncing applications: $e');
    }
  }

  Future<void> _refreshApplications() async {
    await _loadApplications();
    if (_isConnected) {
      await _syncPendingApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          // Manual sync button
          if (_hasPendingApplications())
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync pending applications',
              onPressed: _isConnected
                  ? () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Syncing pending applications...')),
                      );
                      await _syncPendingApplications();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync complete!')),
                      );
                    }
                  : null,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshApplications,
        child: Column(
          children: [
            // Network status indicator for sync status
            if (!_isConnected && _hasPendingApplications())
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
                        'You are offline. Some applications show as "Pending" until you reconnect. Pull down to refresh when back online.',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Pending applications banner when online
            if (_isConnected && _hasPendingApplications())
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.blue.shade800),
                    const SizedBox(width: 8.0),
                    const Expanded(
                      child: Text(
                        'You have pending applications that need to be synced. Tap the sync button to submit them.',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _buildApplicationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apply for scholarships to see them here',
              style: TextStyle(
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final application = _applications[index];
        return _buildApplicationCard(application);
      },
    );
  }

  Widget _buildApplicationCard(Application application) {
    final formatter = NumberFormat.currency(symbol: '₵');
    final dateFormatter = DateFormat('MMM d, yyyy');

    // Format date
    DateTime? appliedDate;
    try {
      appliedDate = DateTime.parse(application.appliedDate);
    } catch (e) {
      // Use current date if parsing fails
      appliedDate = DateTime.now();
    }

    // Determine status color
    Color statusColor;
    switch (application.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
        break;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to application details screen
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passport photo thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildPassportPhoto(application.passportPhotoPath),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Scholarship details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.scholarshipName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.provider,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(application.amount),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(application.appliedDate))}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${application.status}',
                          style: TextStyle(
                            color: application.status == 'Submitted'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        // Display Application Number if available
                        if (application.applicationNumber != null &&
                            application.applicationNumber!.isNotEmpty)
                          Text(
                            'Application #: ${application.applicationNumber}',
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          application.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Applied: ${dateFormatter.format(appliedDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassportPhoto(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Error loading passport photo: $e');
    }

    // Fallback
    return const Icon(
      Icons.person,
      size: 32,
      color: Colors.grey,
    );
  }

  // Check if there are any pending applications
  bool _hasPendingApplications() {
    return _applications.any((app) => app.status.toLowerCase() == 'pending');
  }
}

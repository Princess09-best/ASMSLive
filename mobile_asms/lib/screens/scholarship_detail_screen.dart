import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../config/app_constants.dart';
import '../models/scholarship.dart';

class ScholarshipDetailScreen extends StatefulWidget {
  final int scholarshipId;

  const ScholarshipDetailScreen({
    super.key,
    required this.scholarshipId,
  });

  @override
  State<ScholarshipDetailScreen> createState() =>
      _ScholarshipDetailScreenState();
}

class _ScholarshipDetailScreenState extends State<ScholarshipDetailScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _scholarshipDetails;

  @override
  void initState() {
    super.initState();
    _fetchScholarshipDetails();
  }

  Future<void> _fetchScholarshipDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Connect to the real API endpoint
      final uri = Uri.parse(
          'http://10.0.2.2/ASMSLive/api/scholarships/${widget.scholarshipId}');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data.containsKey('scholarship')) {
          setState(() {
            _scholarshipDetails = data['scholarship'];
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load scholarship details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load scholarship details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarship Details'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildApplyButton(),
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
              onPressed: _fetchScholarshipDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_scholarshipDetails == null) {
      return const Center(
        child: Text('Scholarship not found.'),
      );
    }

    // Format amount with appropriate currency
    final formatter = NumberFormat.currency(symbol: '₵');
    final amount = double.tryParse(
            _scholarshipDetails!['ScholarAmount']?.toString() ?? '0') ??
        0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scholarship header
          Text(
            _scholarshipDetails!['SchemeName'] ?? 'Scholarship',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          Text(
            _scholarshipDetails!['Organization'] ?? 'Unknown Provider',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 16),

          // Amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scholarship Amount',
                        style: TextStyle(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                      Text(
                        formatter.format(amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details table
          _buildDetailRow(
              'Category', _scholarshipDetails!['Category'] ?? 'Not specified'),
          _buildDetailRow(
              'Criteria', _scholarshipDetails!['Criteria'] ?? 'Not specified'),
          _buildDetailRow(
              'Deadline', _formatDate(_scholarshipDetails!['LastDate'])),
          _buildDetailRow('Documents Required',
              _scholarshipDetails!['DocomentRequired'] ?? 'Not specified'),
          _buildDetailRow('Description',
              _scholarshipDetails!['ScholarDesc'] ?? 'Not specified'),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Not specified';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, y').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ||
                _errorMessage.isNotEmpty ||
                _scholarshipDetails == null
            ? null
            : () {
                // TODO: Implement application submission
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application feature coming soon!'),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('APPLY NOW'),
      ),
    );
  }
}

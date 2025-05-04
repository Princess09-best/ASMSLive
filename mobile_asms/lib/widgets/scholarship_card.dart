import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import 'package:intl/intl.dart';
import '../screens/scholarship_detail_screen.dart';

class ScholarshipCard extends StatelessWidget {
  final int id;
  final String name;
  final String provider;
  final double amount;
  final String deadline;
  final String location;
  final double distance;

  const ScholarshipCard({
    super.key,
    required this.id,
    required this.name,
    required this.provider,
    required this.amount,
    required this.deadline,
    required this.location,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₵');
    final deadlineDate = DateTime.parse(deadline);
    final isExpired = deadlineDate.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to scholarship detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScholarshipDetailScreen(
                scholarshipId: id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scholarship icon or logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Scholarship info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider,
                          style: const TextStyle(
                            color: AppConstants.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Amount
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 16,
                              color: AppConstants.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatter.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location and deadline
              Row(
                children: [
                  // Location
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppConstants.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Deadline
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isExpired
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? 'Expired'
                              : DateFormat('MMM d, y').format(deadlineDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isExpired
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
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
}

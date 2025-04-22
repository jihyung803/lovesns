import 'package:flutter/material.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:new_couple_app/services/auth_service.dart'; // Assuming this is the location of AuthService

class ProfileHeader extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final int postCount;
  final int currencyCount;
  final DateTime? relationshipStartDate;
  final String? partnerId;

  const ProfileHeader({
    Key? key,
    required this.username,
    this.profileImageUrl,
    required this.postCount,
    required this.currencyCount,
    this.relationshipStartDate,
    this.partnerId,
  }) : super(key: key);

  

  @override
  Widget build(BuildContext context) {
    // Calculate relationship duration if available
    String relationshipDuration = 'Not set';
    if (relationshipStartDate != null) {
      final now = DateTime.now();
      final difference = now.difference(relationshipStartDate!);
      final days = difference.inDays;
      relationshipDuration = '$days days';
      // if (days < 30) {
      //   relationshipDuration = '$days days';
      // } else if (days < 365) {
      //   final months = days ~/ 30;
      //   relationshipDuration = '$months months';
      // } else {
      //   final years = days ~/ 365;
      //   final remainingMonths = (days % 365) ~/ 30;
      //   relationshipDuration = '$years years';
      //   if (remainingMonths > 0) {
      //     relationshipDuration += ', $remainingMonths months';
      //   }
      // }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color.fromARGB(255, 25, 17, 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and stats
          Row(
            children: [
              // Profile picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 238, 238, 255),
                  image: profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImageUrl == null
                    ? Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Posts', postCount.toString()),
                    FutureBuilder<int>(
                      future: Provider.of<AuthService>(context, listen: false).getCoupleCurrency(),
                      builder: (context, snapshot) {
                        final currencyCount = snapshot.data ?? 0;
                        return _buildStat('Coins', currencyCount.toString());
                      },
                    ),
                    _buildStat(
                      'Together',
                      relationshipDuration,
                      isMultiLine: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Username
          Text(
            username,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Relationship date
          if (relationshipStartDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Since ${DateFormat('MMM d, yyyy').format(relationshipStartDate!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          
          // Connected with partner status
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  partnerId != null ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: partnerId != null ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  partnerId != null ? 'Connected with partner' : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: partnerId != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isMultiLine = false}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
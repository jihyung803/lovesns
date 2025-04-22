import 'package:flutter/material.dart';
import 'package:new_couple_app/config/app_theme.dart';

class StoryBubble extends StatelessWidget {
  final String? imageUrl;
  final bool isViewed;
  final bool isCreateBubble;
  final String? missionTitle;
  final String? missionDescription;
  final VoidCallback onTap;

  const StoryBubble({
    Key? key,
    this.imageUrl,
    this.isViewed = false,
    this.isCreateBubble = false,
    this.missionTitle,
    this.missionDescription,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            // Story circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCreateBubble || !isViewed
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isViewed && !isCreateBubble
                    ? Border.all(color: Colors.grey.shade300, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: isCreateBubble
                    ? const Icon(
                        Icons.camera_alt,
                        color: AppTheme.primaryColor,
                        size: 23,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            
            // Label
            Text(
              isCreateBubble
                  ? 'Today Mission'
                  : 'Story',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isViewed && !isCreateBubble
                    ? Colors.grey.shade600
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show mission info when tapped
  void _showMissionInfo(BuildContext context) {
    if (!isCreateBubble || missionTitle == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                missionTitle!,
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                missionDescription ?? 'Complete this mission to earn rewards!',
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onTap();
                },
                child: const Text('Start Mission'),
              ),
            ],
          ),
        );
      },
    );
  }
}
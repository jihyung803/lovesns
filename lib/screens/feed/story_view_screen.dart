import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stories/flutter_stories.dart' as flutter_stories;
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:new_couple_app/models/story.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/config/app_theme.dart';

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({Key? key}) : super(key: key);

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  List<Story> _stories = [];
  int _currentStoryIndex = 0;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStory();
    });
  }
  
  Future<void> _loadStory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      final coupleId = Provider.of<AuthService>(context, listen: false).currentUser?.coupleId;
      
      if (coupleId == null) {
        setState(() {
          _error = 'Not connected with a partner';
          _isLoading = false;
        });
        return;
      }
      
      // Get the story ID from navigation arguments
      final storyId = ModalRoute.of(context)!.settings.arguments as String;
      
      // Load all stories to get the current one and allow navigation
      await storyService.loadStories();
      
      final stories = storyService.stories;
      if (stories.isEmpty) {
        setState(() {
          _error = 'No stories available';
          _isLoading = false;
        });
        return;
      }
      
      // Find the index of the requested story
      final index = stories.indexWhere((s) => s.id == storyId);
      if (index == -1) {
        setState(() {
          _error = 'Story not found';
          _isLoading = false;
        });
        return;
      }
      
      // Mark story as viewed
      await storyService.markStoryAsViewed(storyId);
      
      setState(() {
        _stories = stories;
        _currentStoryIndex = index;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Navigate to next story or close if last one
  void _onStoryComplete() {
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingIndicator(),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: ErrorDialog(
          message: _error!,
          onRetry: () => Navigator.pop(context),
        ),
      );
    }
    
    if (_stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    final currentStory = _stories[_currentStoryIndex];
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: flutter_stories.Story(
          onFlashForward: _onStoryComplete,
          onFlashBack: () {
            if (_currentStoryIndex > 0) {
              setState(() {
                _currentStoryIndex--;
              });
            }
          },
          momentCount: 1, // Each story has 1 moment/segment
          momentDurationGetter: (idx) => const Duration(seconds: 5),
          momentBuilder: (context, momentIndex) {
            return Stack(
              children: [
                // Story image - 로컬 이미지와 네트워크 이미지 처리 구분
                Center(
                  child: currentStory.isLocalImage
                    ? Image.file(
                        File(currentStory.imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading local story image: $error');
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                          );
                        },
                      )
                    : Image.network(
                        currentStory.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading network story image: $error');
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                          );
                        },
                      ),
                ),
                
                // Caption
                Positioned(
                  bottom: 50,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentStory.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                // Header with user info and close button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            currentStory.userId == authService.currentUser?.id
                                ? Icons.person
                                : Icons.people,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentStory.userId == authService.currentUser?.id
                                    ? 'You'
                                    : 'Partner',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Mission: ${currentStory.missionTitle}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Story navigation indicators
                if (_stories.length > 1)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 60.0),
                      child: Row(
                        children: List.generate(
                          _stories.length,
                          (index) => Expanded(
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index == _currentStoryIndex
                                    ? Colors.white
                                    : index < _currentStoryIndex
                                        ? Colors.grey
                                        : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
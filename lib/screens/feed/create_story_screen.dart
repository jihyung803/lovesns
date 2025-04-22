import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkMissionAvailability();
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
  
  Future<void> _checkMissionAvailability() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      await storyService.loadTodayMission();
      
      if (storyService.todayMission == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No mission available today')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _takePhoto() async {
    // Check for camera permission
    final PermissionStatus status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required to take photos')),
      );
      return;
    }
    
    // Show image source selection
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<void> _submitStory() async {
    // Validate input
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo for your story')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      final bool success = await storyService.createStory(
        _selectedImage!,
        _captionController.text.trim(),
      );
      
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create story: ${storyService.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create story: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);
    final mission = storyService.todayMission;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Mission'),
        actions: [
          if (_selectedImage != null)
            TextButton(
              onPressed: _isLoading ? null : _submitStory,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Processing...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mission information
                  if (mission != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mission.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: AppTheme.accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reward: ${mission.rewardAmount} coins',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  // Selected image preview
                  if (_selectedImage != null)
                    Container(
                      height: 400,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 400,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 64,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Take a photo for your mission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Caption input
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _captionController,
                      decoration: const InputDecoration(
                        hintText: 'Add a caption...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _selectedImage == null
          ? FloatingActionButton(
              onPressed: _takePhoto,
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}
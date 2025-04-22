import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/story_service.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';

class ImageStoryScreen extends StatefulWidget {
  const ImageStoryScreen({Key? key}) : super(key: key);

  @override
  State<ImageStoryScreen> createState() => _ImageStoryScreenState();
}

class _ImageStoryScreenState extends State<ImageStoryScreen> with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isPhotoLibraryVisible = false;
  
  final TextEditingController _captionController = TextEditingController();
  late AnimationController _animationController;
  final GlobalKey _dragTargetKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 앱이 시작되면 바로 이미지 선택 다이얼로그 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage(ImageSource.camera);
    });
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isDenied) {
      await permission.request();
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        await _checkPermission(Permission.camera);
      } else {
        await _checkPermission(Permission.photos);
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isEditing = true;
          _isPhotoLibraryVisible = false;
        });
      } else {
        // 사용자가 이미지 선택을 취소했을 경우
        if (!_isEditing && _selectedImage == null) {
          // 만약 처음 진입 시 취소했다면 화면을 닫음
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<void> _submitStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo for your story')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      await storyService.loadTodayMission();
      
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
  
  void _togglePhotoLibrary() {
    setState(() {
      _isPhotoLibraryVisible = !_isPhotoLibraryVisible;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingIndicator(message: 'Creating your story...'),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isEditing ? _buildEditingUI() : _buildCameraUI(),
    );
  }
  
  Widget _buildCameraUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          const Text(
            '카메라 화면',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리에서 선택'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditingUI() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // 위로 스와이프하면 갤러리 열기
        if (details.primaryVelocity! < -300) {
          _pickImage(ImageSource.gallery);
        }
      },
      child: Stack(
        children: [
          // 이미지 미리보기
          Positioned.fill(
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  )
                : Container(color: Colors.black),
          ),
          
          // 캡션 오버레이
          SafeArea(
            child: Column(
              children: [
                // 상단 컨트롤 바
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditing = false;
                            _selectedImage = null;
                            _captionController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _submitStory,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // 위로 스와이프 안내
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white.withOpacity(0.8),
                        size: 36,
                      ),
                      Text(
                        '위로 스와이프하여 다른 사진 선택',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 캡션 입력
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '캡션 추가...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
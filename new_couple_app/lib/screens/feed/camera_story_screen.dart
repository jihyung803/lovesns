// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:new_couple_app/config/app_theme.dart';
// import 'package:new_couple_app/services/story_service.dart';
// import 'package:new_couple_app/widgets/common/loading_indicator.dart';

// class CameraStoryScreen extends StatefulWidget {
//   const CameraStoryScreen({Key? key}) : super(key: key);

//   @override
//   State<CameraStoryScreen> createState() => _CameraStoryScreenState();
// }

// class _CameraStoryScreenState extends State<CameraStoryScreen> with SingleTickerProviderStateMixin {
//   CameraController? _cameraController;
//   Future<void>? _initializeControllerFuture;
//   bool _isCameraInitialized = false;
//   File? _capturedImage;
//   bool _isEditing = false;
//   bool _isLoading = false;
  
//   final TextEditingController _captionController = TextEditingController();
//   late AnimationController _animationController;
//   GlobalKey _dragTargetKey = GlobalKey();
  
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _checkCameraPermission();
//   }
  
//   @override
//   void dispose() {
//     _captionController.dispose();
//     _cameraController?.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _checkCameraPermission() async {
//     final PermissionStatus status = await Permission.camera.request();
//     if (status.isDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera permission is required to take photos')),
//       );
//       Navigator.pop(context);
//       return;
//     }
    
//     _initCamera();
//   }
  
//   Future<void> _initCamera() async {
//     final cameras = await availableCameras();
//     if (cameras.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No cameras available')),
//       );
//       Navigator.pop(context);
//       return;
//     }
    
//     _cameraController = CameraController(
//       cameras[0],
//       ResolutionPreset.high,
//       enableAudio: false,
//     );
    
//     _initializeControllerFuture = _cameraController?.initialize();
    
//     if (mounted) {
//       setState(() {
//         _isCameraInitialized = true;
//       });
//     }
//   }
  
//   Future<void> _takePhoto() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera is not initialized')),
//       );
//       return;
//     }
    
//     try {
//       final XFile photo = await _cameraController!.takePicture();
//       setState(() {
//         _capturedImage = File(photo.path);
//         _isEditing = true;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to take photo: $e')),
//       );
//     }
//   }
  
//   Future<void> _openGallery() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? pickedFile = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 70,
//       );
      
//       if (pickedFile != null) {
//         setState(() {
//           _capturedImage = File(pickedFile.path);
//           _isEditing = true;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to pick image: $e')),
//       );
//     }
//   }
  
//   Future<void> _submitStory() async {
//     if (_capturedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please take a photo for your story')),
//       );
//       return;
//     }
    
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final storyService = Provider.of<StoryService>(context, listen: false);
//       await storyService.loadTodayMission();
      
//       final bool success = await storyService.createStory(
//         _capturedImage!,
//         _captionController.text.trim(),
//       );
      
//       if (success) {
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to create story: ${storyService.error}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create story: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: LoadingIndicator(message: 'Creating your story...'),
//       );
//     }
    
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _isEditing ? _buildEditingUI() : _buildCameraUI(),
//     );
//   }
  
//   Widget _buildCameraUI() {
//     return Stack(
//       children: [
//         // Camera preview
//         Positioned.fill(
//           child: !_isCameraInitialized
//               ? const Center(child: CircularProgressIndicator())
//               : FutureBuilder<void>(
//                   future: _initializeControllerFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.done) {
//                       return CameraPreview(_cameraController!);
//                     } else {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                   },
//                 ),
//         ),
        
//         // Swipe up handle
//         Positioned(
//           bottom: 20,
//           left: 0,
//           right: 0,
//           child: GestureDetector(
//             onVerticalDragEnd: (details) {
//               if (details.primaryVelocity! < -300) {
//                 _openGallery();
//               }
//             },
//             child: Center(
//               child: Column(
//                 children: [
//                   Icon(
//                     Icons.keyboard_arrow_up,
//                     color: Colors.white.withOpacity(0.8),
//                     size: 36,
//                   ),
//                   Text(
//                     'Swipe up for gallery',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.8),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
        
//         // Camera controls
//         SafeArea(
//           child: Column(
//             children: [
//               // Top bar with close button
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.4),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const Spacer(),
              
//               // Bottom capture button
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 80.0),
//                 child: Center(
//                   child: GestureDetector(
//                     onTap: _takePhoto,
//                     child: Container(
//                       width: 70,
//                       height: 70,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: Colors.white,
//                           width: 4,
//                         ),
//                       ),
//                       child: Container(
//                         margin: const EdgeInsets.all(3),
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildEditingUI() {
//     return Stack(
//       children: [
//         // Image preview
//         Positioned.fill(
//           child: _capturedImage != null
//               ? Image.file(
//                   _capturedImage!,
//                   fit: BoxFit.cover,
//                 )
//               : Container(color: Colors.black),
//         ),
        
//         // Caption overlay
//         SafeArea(
//           child: Column(
//             children: [
//               // Top bar with controls
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _isEditing = false;
//                           _capturedImage = null;
//                           _captionController.clear();
//                         });
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.4),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.arrow_back,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: _submitStory,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryColor.withOpacity(0.8),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Text(
//                           'Share',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const Spacer(),
              
//               // Caption input
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: TextField(
//                     controller: _captionController,
//                     style: const TextStyle(color: Colors.white),
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       hintText: 'Add a caption...',
//                       hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.all(16),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
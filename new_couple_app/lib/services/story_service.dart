import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:new_couple_app/models/story.dart';
import 'package:new_couple_app/services/auth_service.dart';

class StoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService;
  
  List<Story> _stories = [];
  List<Mission> _missions = [];
  Mission? _todayMission;
  bool _isLoading = false;
  String? _error;
  
  List<Story> get stories => _stories;
  List<Mission> get missions => _missions;
  Mission? get todayMission => _todayMission;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  StoryService({AuthService? authService})
      : _authService = authService ?? AuthService();
  
  Future<void> loadStories() async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final coupleId = _authService.currentUser!.coupleId!;
      final QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .where('coupleId', isEqualTo: coupleId)
          .where('expiresAt', isGreaterThan: Timestamp.now().millisecondsSinceEpoch)
          .orderBy('expiresAt', descending: true)
          .get();
      
      _stories = snapshot.docs
          .map((doc) => Story.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadTodayMission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get today's date (without time)
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      final QuerySnapshot snapshot = await _firestore
          .collection('missions')
          .where('date', isEqualTo: todayDate.millisecondsSinceEpoch)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        _todayMission = Mission.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
      } else {
        // If no mission found for today, create a new one
        await _createDefaultMission(todayDate);
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _createDefaultMission(DateTime date) async {
    try {
      final String missionId = const Uuid().v4();
      
      // Create a default mission with a random prompt
      final List<String> defaultPrompts = [
        'Take a photo of your meal today',
        'Share a selfie of your current mood',
        'Capture something beautiful you saw today',
        'Show what you\'re working on right now',
        'Take a photo of your outfit today',
        'Share a glimpse of your surroundings',
        'Capture a moment that made you smile today',
        'Take a photo of something that reminds you of your partner',
      ];
      
      final int randomIndex = DateTime.now().millisecondsSinceEpoch % defaultPrompts.length;
      final String randomPrompt = defaultPrompts[randomIndex];
      
      final Mission newMission = Mission(
        id: missionId,
        title: 'Daily Mission',
        description: randomPrompt,
        rewardAmount: 10,
        isActive: true,
        date: date,
      );
      
      await _firestore.collection('missions').doc(missionId).set(newMission.toJson());
      
      _todayMission = newMission;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
  
  Future<bool> createStory(File image, String caption) async {
    if (_authService.currentUser == null || 
        _authService.currentUser!.coupleId == null || 
        _todayMission == null) {
      _error = 'Unable to create story. Please try again.';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final String storyId = const Uuid().v4();
      
      // Upload image
      final String path = 'stories/${_authService.currentUser!.id}/$storyId.jpg';
      final Reference ref = _storage.ref().child(path);
      await ref.putFile(image);
      final String imageUrl = await ref.getDownloadURL();
      
      // Create story with 24hr expiration
      final DateTime now = DateTime.now();
      final DateTime expiresAt = now.add(const Duration(hours: 24));
      
      final Story newStory = Story(
        id: storyId,
        userId: _authService.currentUser!.id,
        coupleId: _authService.currentUser!.coupleId!,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: now,
        expiresAt: expiresAt,
        missionId: _todayMission!.id,
        missionTitle: _todayMission!.title,
      );
      
      await _firestore.collection('stories').doc(storyId).set(newStory.toJson());
      
      // Add currency reward for completing mission
      // StoryService의 createStory 메서드 수정
      // Add currency reward for completing mission
      await _authService.updateCurrency(_todayMission!.rewardAmount, 
          reason: 'Completed mission: ${_todayMission!.title}');
      
      // Add to local list
      _stories.insert(0, newStory);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> markStoryAsViewed(String storyId) async {
    try {
      // Find story
      final int index = _stories.indexWhere((story) => story.id == storyId);
      if (index == -1) {
        _error = 'Story not found';
        return false;
      }
      
      // Update in Firestore
      await _firestore.collection('stories').doc(storyId).update({
        'isViewed': true,
      });
      
      // Update local story
      _stories[index] = _stories[index].copyWith(isViewed: true);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  Future<List<Story>> getStoriesByUser(String userId) async {
    try {
      print('프로필: 스토리 조회 시작 - 사용자 ID: $userId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('프로필: 조회된 스토리 수: ${snapshot.docs.length}');
      
      return snapshot.docs
          .map((doc) => Story.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('프로필: 스토리 조회 오류: $e');
      _error = e.toString();
      return [];
    }
  }
  
  Future<bool> deleteStory(String storyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find story index
      final int index = _stories.indexWhere((story) => story.id == storyId);
      if (index == -1) {
        _error = 'Story not found';
        return false;
      }
      
      final Story story = _stories[index];
      
      // Check if user has permission to delete
      if (story.userId != _authService.currentUser!.id) {
        _error = 'You do not have permission to delete this story';
        return false;
      }
      
      // Delete image from storage
      try {
        final ref = _storage.refFromURL(story.imageUrl);
        await ref.delete();
      } catch (e) {
        // Continue even if image deletion fails
        print('Failed to delete image: ${e.toString()}');
      }
      
      // Delete story document
      await _firestore.collection('stories').doc(storyId).delete();
      
      // Remove from local list
      _stories.removeAt(index);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
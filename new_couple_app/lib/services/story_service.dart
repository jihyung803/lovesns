import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:new_couple_app/models/story.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService;
  
  StoryService(this._authService) {
    // OpenAI API 키 설정 (앱 시작 시 한 번만 설정)
    OpenAI.apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  }
  
  List<Story> _stories = [];
  List<Story> _pastStories = []; // 지난 스토리들을 저장하는 리스트 추가
  List<Mission> _missions = [];
  Mission? _todayMission;
  bool _isLoading = false;
  String? _error;
  
  List<Story> get stories => _stories;
  List<Story> get pastStories => _pastStories;
  List<Mission> get missions => _missions;
  Mission? get todayMission => _todayMission;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
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
      
      // 과거 스토리들도 함께 로드 (최근 20개 정도만)
      await _loadPastStories(coupleId);
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 과거 스토리들을 로드하는 메서드 추가
  Future<void> _loadPastStories(String coupleId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .where('coupleId', isEqualTo: coupleId)
          .orderBy('createdAt', descending: true)
          .limit(20) // 최근 20개만 가져옴
          .get();
      
      _pastStories = snapshot.docs
          .map((doc) => Story.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('과거 스토리 로드 실패: $e');
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
        notifyListeners();
      } else {
        // 오늘의 미션이 없으면 새로 생성
        // 이전 스토리들을 분석해서 중복되지 않는 미션 생성
        if (_authService.currentUser != null && _authService.currentUser!.coupleId != null) {
          await _loadPastStories(_authService.currentUser!.coupleId!);
        }
        await _createUniquePersonalizedMission(todayDate);
      }
      
    } catch (e) {
      _error = e.toString();
      // 오류 발생 시 기본 미션 생성
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      await _createDefaultMission(todayDate);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 이전 스토리 내용을 활용한 개인화된 미션 생성
  Future<void> _createUniquePersonalizedMission(DateTime date) async {
    try {
      final String missionId = const Uuid().v4();
      
      // 이전 미션 목록 가져오기
      List<String> pastMissions = [];
      if (_pastStories.isNotEmpty) {
        pastMissions = _pastStories
            .where((story) => story.missionTitle.isNotEmpty)
            .map((story) => story.missionTitle)
            .toList();
      }
      
      // 이전 스토리 캡션에서 키워드 추출
      List<String> pastCaptions = [];
      if (_pastStories.isNotEmpty) {
        pastCaptions = _pastStories
            .where((story) => story.caption.isNotEmpty)
            .map((story) => story.caption)
            .toList();
      }
      
      // OpenAI API를 사용하여 맞춤형 미션 생성
      String prompt = "커플이 함께할 수 있는 재미있고 간단한 미션을 한 문장으로 생성해줘.";
      
      // 이전 미션 정보 추가
      if (pastMissions.isNotEmpty) {
        String pastMissionsText = pastMissions.take(5).join(", ");
        prompt += " 다음은 최근에 했던 미션들이니 겹치지 않게 해줘: '$pastMissionsText'.";
      }
      
      // 이전 스토리 캡션 내용 활용
      if (pastCaptions.isNotEmpty) {
        String pastCaptionsText = pastCaptions.take(3).join(", ");
        prompt += " 커플이 관심 있는 내용: '$pastCaptionsText'에 관련된 미션을 만들어보는 것도 좋을 것 같아.";
      }
      
      final response = await OpenAI.instance.completion.create(
        model: "gpt-3.5-turbo-instruct",
        prompt: prompt,
        maxTokens: 50,
        temperature: 0.7,
      );
      
      final String missionPrompt = response.choices.first.text.trim();
      print('생성된 맞춤형 미션: $missionPrompt');
      
      // 미션 객체 생성
      final Mission newMission = Mission(
        id: missionId,
        title: '오늘의 미션',
        description: missionPrompt,
        rewardAmount: 10,
        isActive: true,
        date: date,
      );
      
      // Firestore에 저장
      await _firestore.collection('missions').doc(missionId).set(newMission.toJson());
      _todayMission = newMission;
      
    } catch (e) {
      print('맞춤형 미션 생성 실패: $e');
      // API 실패 시 기본 미션 생성
      await _createDefaultMission(date);
    }
  }
  
  // 기본 미션 선택 메서드 (이전에 사용한 미션은 제외)
  Future<void> _createDefaultMission(DateTime date) async {
    try {
      final String missionId = const Uuid().v4();
      final String missionPrompt = _getUniqueDefaultMissionPrompt();
      
      final Mission newMission = Mission(
        id: missionId,
        title: '오늘의 미션',
        description: missionPrompt,
        rewardAmount: 10,
        isActive: true,
        date: date,
      );
      
      await _firestore.collection('missions').doc(missionId).set(newMission.toJson());
      _todayMission = newMission;
      
    } catch (e) {
      print('기본 미션 생성 실패: $e');
      _error = e.toString();
    }
  }
  
  // 이전에 사용하지 않은 기본 미션 선택
  String _getUniqueDefaultMissionPrompt() {
    final List<String> defaultPrompts = [
      '오늘 먹은 음식 사진 공유하기',
      '현재 기분을 셀카로 표현하기',
      '오늘 본 아름다운 것 사진 찍기',
      '지금 하고 있는 일 공유하기',
      '오늘의 착장 사진 찍기',
      '주변 환경 한 컷 공유하기',
      '오늘 웃게 만든 순간 포착하기',
      '파트너를 생각나게 하는 무언가 사진 찍기',
      '서로에게 손편지 쓰기',
      '같은 장소에서 다른 각도로 사진 찍기',
      '하루동안 SNS 금지하고 서로에게만 연락하기',
      '상대방의 취미 한번 따라해보기',
      '오늘 가장 감사한 순간 공유하기',
      '서로의 의상 코디해주기',
      '서로에게 깜짝 선물하기',
      '함께 요리하고 사진 찍기',
      '서로의 하루 일과 동영상으로 기록하기',
      '추억의 장소 방문하고 인증하기',
      '같은 주제로 각자 그림 그려서 비교하기',
      '서로의 이름 첫 글자로 시작하는 물건 찾기',
    ];
    
    // 최근에 사용한 미션 제외
    List<String> recentMissions = [];
    if (_pastStories.isNotEmpty) {
      recentMissions = _pastStories
          .where((story) => story.missionTitle.isNotEmpty)
          .map((story) => story.missionTitle)
          .toList();
    }
    
    // 사용하지 않은 미션만 필터링
    List<String> unusedPrompts = defaultPrompts.where((prompt) => 
        !recentMissions.contains(prompt)).toList();
    
    // 사용하지 않은 미션이 없으면 전체 목록에서 선택
    if (unusedPrompts.isEmpty) {
      unusedPrompts = defaultPrompts;
    }
    
    final int randomIndex = DateTime.now().millisecondsSinceEpoch % unusedPrompts.length;
    return unusedPrompts[randomIndex];
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
      await _authService.updateCurrency(_todayMission!.rewardAmount, 
          reason: 'Completed mission: ${_todayMission!.title}');
      
      // Add to local lists
      _stories.insert(0, newStory);
      _pastStories.insert(0, newStory);
      
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
      
      // past stories에도 업데이트
      final int pastIndex = _pastStories.indexWhere((story) => story.id == storyId);
      if (pastIndex != -1) {
        _pastStories[pastIndex] = _pastStories[pastIndex].copyWith(isViewed: true);
      }
      
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
      
      // Remove from local lists
      _stories.removeAt(index);
      
      final int pastIndex = _pastStories.indexWhere((s) => s.id == storyId);
      if (pastIndex != -1) {
        _pastStories.removeAt(pastIndex);
      }
      
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
  
  // 커플의 스토리 내용을 분석하여 관심사 키워드 추출
  Future<List<String>> analyzeInterests() async {
    if (_pastStories.isEmpty) return [];
    
    try {
      // 모든 캡션 텍스트 결합
      final String allCaptions = _pastStories
          .where((story) => story.caption.isNotEmpty)
          .map((story) => story.caption)
          .join(' ');
      
      if (allCaptions.isEmpty) return [];
      
      // OpenAI API를 사용하여 관심사 추출
      final response = await OpenAI.instance.completion.create(
        model: "gpt-3.5-turbo-instruct",
        prompt: "다음 텍스트에서 주요 관심사나 활동을 5개의 키워드로 추출해주세요:\n$allCaptions",
        maxTokens: 50,
        temperature: 0.5,
      );
      
      final String result = response.choices.first.text.trim();
      
      // 결과를 쉼표나 줄바꿈으로 분리하여 리스트로 변환
      List<String> keywords = result.split(RegExp(r'[,\n]'))
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toList();
      
      return keywords;
    } catch (e) {
      print('관심사 분석 실패: $e');
      return [];
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
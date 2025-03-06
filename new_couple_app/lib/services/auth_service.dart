import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_couple_app/models/user.dart' as app;

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  app.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  app.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is already logged in
      firebase.User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _fetchUserData(firebaseUser.uid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String userId) async {
    try {
      print("사용자 데이터 가져오기: $userId");
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      print("문서 존재 여부: ${userDoc.exists}");
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print("사용자 데이터: $userData");
        _currentUser = app.User.fromJson(userData);
        print("변환된 사용자 객체: ${_currentUser?.email}");
      } else {
        print("사용자 문서가 없음");
      }
    } catch (e) {
      print("사용자 데이터 가져오기 오류: $e");
      _error = e.toString();
    }
  }

  bool get isPartnerConnected {
    print('현재 사용자: ${_currentUser?.id}');
    print('파트너 ID: ${_currentUser?.partnerId}');
    print('커플 ID: ${_currentUser?.coupleId}');
    return _currentUser?.partnerId != null && _currentUser?.coupleId != null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      firebase.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // 사용자 데이터 가져오기 시도
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // 사용자 문서가 없으면 새로 생성
          app.User newUser = app.User(
            id: userCredential.user!.uid,
            email: email,
            username: email.split('@')[0], // 이메일에서 username 추출
            createdAt: DateTime.now(),
          );

          await _firestore.collection('users').doc(userCredential.user!.uid).set(newUser.toJson());
          _currentUser = newUser;
        } else {
          // 기존 문서가 있으면 데이터 가져오기
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          _currentUser = app.User.fromJson(userData);
        }
        
        // 로그인 상태 저장
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      firebase.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        app.User newUser = app.User(
          id: userCredential.user!.uid,
          email: email,
          username: username,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set(newUser.toJson());
        _currentUser = newUser;

        // Save login state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // AuthService 클래스에 추가할 메서드
  // AuthService 클래스에 이 메서드를 추가하세요
  Future<bool> setupDevPartner() async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 임시 파트너 및 커플 ID 생성
      // 일관된 커플 ID 사용
      const String devCoupleId = 'dev_couple_123';
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'partnerId': 'dev_partner_123',
        'coupleId': devCoupleId,
      });
      
      _currentUser = _currentUser!.copyWith(
        partnerId: 'dev_partner_123',
        coupleId: devCoupleId,
      );
      
      print('개발용 파트너 설정 완료: 커플 ID = $devCoupleId');
      
      // Firebase에 저장하지 않고 로컬만 업데이트
      
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _currentUser = null;

      // Clear login state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // AuthService 클래스에 추가
  Future<bool> connectWithPartner(String partnerCode) async {
    if (_currentUser == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 파트너 사용자 찾기
      QuerySnapshot query = await _firestore.collection('users')
          .where('id', isEqualTo: partnerCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _error = '파트너를 찾을 수 없습니다.';
        return false;
      }

      // 파트너 정보
      final partnerData = query.docs.first.data() as Map<String, dynamic>;
      final partnerId = partnerData['id'] as String;
      
      // 이미 다른 파트너와 연결되어 있는지 확인
      if (partnerData['partnerId'] != null && partnerData['partnerId'] != _currentUser!.id) {
        _error = '파트너가 이미 다른 사용자와 연결되어 있습니다.';
        return false;
      }
      
      // 커플 ID 생성
      String coupleId = '${_currentUser!.id}_$partnerId';
      
      // 양쪽 사용자 모두 업데이트
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'partnerId': partnerId,
        'coupleId': coupleId,
      });
      
      await _firestore.collection('users').doc(partnerId).update({
        'partnerId': _currentUser!.id,
        'coupleId': coupleId,
      });
      
      // 커플 화폐 초기화
      await _firestore.collection('couple_currencies').doc(coupleId).set({
        'coupleId': coupleId,
        'amount': 100, // 초기 보너스 지급
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'history': [{
          'amount': 100,
          'reason': '커플 연결 보너스',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'userId': _currentUser!.id
        }]
      });
      
      // 현재 사용자 정보 업데이트
      _currentUser = _currentUser!.copyWith(
        partnerId: partnerId,
        coupleId: coupleId,
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile({
    String? username,
    String? profileImageUrl,
    DateTime? relationshipStartDate,
    DateTime? partnerBirthday,
    DateTime? menstrualCycleStart,
    int? menstrualCycleDuration,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> updates = {};
      
      if (username != null) updates['username'] = username;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (relationshipStartDate != null) updates['relationshipStartDate'] = relationshipStartDate.millisecondsSinceEpoch;
      if (partnerBirthday != null) updates['partnerBirthday'] = partnerBirthday.millisecondsSinceEpoch;
      if (menstrualCycleStart != null) updates['menstrualCycleStart'] = menstrualCycleStart.millisecondsSinceEpoch;
      if (menstrualCycleDuration != null) updates['menstrualCycleDuration'] = menstrualCycleDuration;

      await _firestore.collection('users').doc(_currentUser!.id).update(updates);
      
      // Update local user object
      _currentUser = _currentUser!.copyWith(
        username: username ?? _currentUser!.username,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        relationshipStartDate: relationshipStartDate ?? _currentUser!.relationshipStartDate,
        partnerBirthday: partnerBirthday ?? _currentUser!.partnerBirthday,
        menstrualCycleStart: menstrualCycleStart ?? _currentUser!.menstrualCycleStart,
        menstrualCycleDuration: menstrualCycleDuration ?? _currentUser!.menstrualCycleDuration,
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCurrency(int amount, {String? reason}) async {
    if (_currentUser == null || _currentUser!.coupleId == null) return false;

    final coupleId = _currentUser!.coupleId!;
    final docRef = _firestore.collection('couple_currencies').doc(coupleId);
    
    try {
      // 트랜잭션을 사용하여 동시 업데이트 문제 방지
      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          // 문서가 없으면 새로 생성
          transaction.set(docRef, {
            'coupleId': coupleId,
            'amount': amount,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            'history': [{
              'amount': amount,
              'reason': reason ?? 'Initial balance',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'userId': _currentUser!.id
            }]
          });
        } else {
          // 기존 문서 업데이트
          final currentAmount = snapshot.data()?['amount'] as int? ?? 0;
          final newAmount = currentAmount + amount;
          
          if (newAmount < 0) {
            // 잔액 부족
            return false;
          }
          
          // 히스토리 업데이트
          final List<dynamic> history = snapshot.data()?['history'] as List<dynamic>? ?? [];
          history.add({
            'amount': amount,
            'reason': reason ?? (amount > 0 ? 'Earned coins' : 'Spent coins'),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': _currentUser!.id
          });
          
          transaction.update(docRef, {
            'amount': newAmount,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            'history': history
          });
        }
        
        return true;
      });
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<int> getCoupleCurrency() async {
    if (_currentUser == null || _currentUser!.coupleId == null) return 0;
    
    try {
      final coupleId = _currentUser!.coupleId!;
      final docSnapshot = await _firestore.collection('couple_currencies').doc(coupleId).get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data()?['amount'] as int? ?? 0;
      }
      
      return 0;
    } catch (e) {
      _error = e.toString();
      return 0;
    }
  }

  Future<app.User?> getPartnerInfo() async {
    if (_currentUser == null || _currentUser!.partnerId == null) return null;

    try {
      DocumentSnapshot partnerDoc = await _firestore.collection('users').doc(_currentUser!.partnerId).get();
      if (partnerDoc.exists) {
        return app.User.fromJson(partnerDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // AuthService 클래스에 다음 메서드 추가
  Future<void> initializeCoupleCurrency() async {
    if (_currentUser == null || _currentUser!.coupleId == null) return;
    
    final coupleId = _currentUser!.coupleId!;
    
    // 커플 화폐 문서가 이미 존재하는지 확인
    final docRef = _firestore.collection('couple_currencies').doc(coupleId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // 새 커플 화폐 문서 생성
      await docRef.set({
        'coupleId': coupleId,
        'amount': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'history': []
      });
    }
  }

  
}
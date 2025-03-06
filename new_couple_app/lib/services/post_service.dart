import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:new_couple_app/models/post.dart';
import 'package:new_couple_app/models/user.dart';
import 'package:new_couple_app/services/auth_service.dart';

class PostService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService;
  
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  PostService({AuthService? authService})
      : _authService = authService ?? AuthService();
  
  Future<void> loadPosts() async {
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
          .collection('posts')
          .where('coupleId', isEqualTo: coupleId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _posts = snapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Post?> getPostById(String postId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return Post.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  Future<bool> createPost(String content, List<File> images) async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final String postId = const Uuid().v4();
      final List<String> imageUrls = [];
      
      // Upload images if any
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final path = 'posts/${_authService.currentUser!.id}/$postId/$i.jpg';
          final ref = _storage.ref().child(path);
          await ref.putFile(images[i]);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }
      
      // Create post document
      final Post newPost = Post(
        id: postId,
        userId: _authService.currentUser!.id,
        coupleId: _authService.currentUser!.coupleId!,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('posts').doc(postId).set(newPost.toJson());
      
      
      // Refresh posts list
      _posts.insert(0, newPost);
      await _authService.updateCurrency(5, reason: 'Posted a new photo');
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find post index
      final int index = _posts.indexWhere((post) => post.id == postId);
      if (index == -1) {
        _error = 'Post not found';
        return false;
      }
      
      final Post post = _posts[index];
      
      // Check if user has permission to delete
      if (post.userId != _authService.currentUser!.id) {
        _error = 'You do not have permission to delete this post';
        return false;
      }
      
      // Delete images from storage
      for (int i = 0; i < post.imageUrls.length; i++) {
        try {
          final ref = _storage.refFromURL(post.imageUrls[i]);
          await ref.delete();
        } catch (e) {
          // Continue even if image deletion fails
          print('Failed to delete image: ${e.toString()}');
        }
      }
      
      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();
      
      // Remove from local list
      _posts.removeAt(index);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> likePost(String postId) async {
    try {
      // Find post
      final int index = _posts.indexWhere((post) => post.id == postId);
      if (index == -1) {
        _error = 'Post not found';
        return false;
      }
      
      final Post post = _posts[index];
      
      // Toggle like status
      final bool newLikeStatus = !post.isLikedByPartner;
      
      // Update in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'isLikedByPartner': newLikeStatus,
        'likeCount': post.likeCount + (newLikeStatus ? 1 : -1),
      });
      
      // Update local post
      _posts[index] = post.copyWith(
        isLikedByPartner: newLikeStatus,
        likeCount: post.likeCount + (newLikeStatus ? 1 : -1),
      );
      await _authService.updateCurrency(2, reason: 'liked a post');

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  Future<bool> addComment(String postId, String content) async {
    if (_authService.currentUser == null) {
      _error = 'User not logged in';
      return false;
    }
    
    try {
      // Find post
      final int index = _posts.indexWhere((post) => post.id == postId);
      if (index == -1) {
        // Try to fetch the post if not in memory
        final Post? fetchedPost = await getPostById(postId);
        if (fetchedPost == null) {
          _error = 'Post not found';
          return false;
        }
        _posts.add(fetchedPost);
      }
      
      final Post post = _posts[index];
      
      // Create new comment
      final Comment newComment = Comment(
        id: const Uuid().v4(),
        userId: _authService.currentUser!.id,
        content: content,
        createdAt: DateTime.now(),
        userImageUrl: _authService.currentUser!.profileImageUrl,
        username: _authService.currentUser!.username,
      );
      
      // Add to comments list
      final List<Comment> updatedComments = [...post.comments, newComment];
      
      // Update in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((comment) => comment.toJson()).toList(),
      });
      
      // Update local post
      _posts[index] = post.copyWith(comments: updatedComments);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      // Find post
      final int postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) {
        _error = 'Post not found';
        return false;
      }
      
      final Post post = _posts[postIndex];
      
      // Find comment
      final int commentIndex = post.comments.indexWhere((comment) => comment.id == commentId);
      if (commentIndex == -1) {
        _error = 'Comment not found';
        return false;
      }
      
      final Comment comment = post.comments[commentIndex];
      
      // Check if user has permission
      if (comment.userId != _authService.currentUser!.id) {
        _error = 'You do not have permission to delete this comment';
        return false;
      }
      
      // Remove comment
      final List<Comment> updatedComments = List.from(post.comments);
      updatedComments.removeAt(commentIndex);
      
      // Update in Firestore
      await _firestore.collection('posts').doc(postId).update({
        'comments': updatedComments.map((comment) => comment.toJson()).toList(),
      });
      
      // Update local post
      _posts[postIndex] = post.copyWith(comments: updatedComments);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  // Fetch posts by user for profile
  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      print('프로필: 사용자 게시글 검색 시작 - 사용자 ID: $userId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('프로필: 쿼리 결과 - ${snapshot.docs.length}개 게시글 찾음');
      
      // 각 문서의 userId 필드 확인 (디버깅용)
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('프로필: 게시글 ID=${doc.id}, userId=${data['userId']}, content=${data['content']}');
      }
      
      final posts = snapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      return posts;
    } catch (e) {
      print('프로필: 사용자 게시글 로드 오류 - $e');
      _error = e.toString();
      return [];
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
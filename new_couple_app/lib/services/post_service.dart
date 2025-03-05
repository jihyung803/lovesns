import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:new_couple_app/models/post.dart';
import 'package:new_couple_app/models/user.dart';
import 'package:new_couple_app/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


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
      final List<String> localImagePaths = [];
      
      // 로컬에 이미지 저장
      if (images.isNotEmpty) {
        print('Saving images locally...');
        final appDir = await getApplicationDocumentsDirectory();
        final postsDir = Directory('${appDir.path}/posts');
        
        // posts 디렉토리 생성 (없는 경우)
        if (!await postsDir.exists()) {
          await postsDir.create(recursive: true);
        }
        
        for (int i = 0; i < images.length; i++) {
          final String fileName = '${postId}_${i}.jpg';
          final String localPath = '${postsDir.path}/$fileName';
          
          print('Copying image to: $localPath');
          final File newFile = await images[i].copy(localPath);
          print('Image saved successfully: ${await newFile.exists()}');
          
          localImagePaths.add(localPath);
        }
      }
      
      // 게시물 생성
      final Post newPost = Post(
        id: postId,
        userId: _authService.currentUser!.id,
        coupleId: _authService.currentUser!.coupleId!,
        content: content,
        imageUrls: localImagePaths,
        isLocalImages: true,  // 로컬 이미지임을 표시
        createdAt: DateTime.now(),
      );
      
      // Firestore에 게시물 저장
      await _firestore.collection('posts').doc(postId).set(newPost.toJson());
      print('Post created with ID: $postId');
      
      // 포스팅 보상으로 통화 추가
      await _authService.updateCurrency(5);
      
      // 게시물 목록 새로고침
      _posts.insert(0, newPost);
      
      return true;
    } catch (e) {
      print('Error creating post: $e');
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
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
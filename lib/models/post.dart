import 'dart:math';
import 'package:new_couple_app/models/user.dart';

class Post {
  final String id;
  final String userId;
  final String coupleId;
  final String content;
  final List<String> imageUrls;
  final bool isLocalImages;  // 추가된 필드
  final DateTime createdAt;
  final int likeCount;
  final List<Comment> comments;
  final bool isLikedByPartner;

  Post({
    required this.id,
    required this.userId,
    required this.coupleId,
    required this.content,
    required this.imageUrls,
    this.isLocalImages = false,  // 기본값은 false
    required this.createdAt,
    this.likeCount = 0,
    this.comments = const [],
    this.isLikedByPartner = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      coupleId: json['coupleId'] as String,
      content: json['content'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>).map((e) => e as String).toList(),
      isLocalImages: json['isLocalImages'] as bool? ?? false,  // 추가된 필드
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      likeCount: json['likeCount'] as int? ?? 0,
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isLikedByPartner: json['isLikedByPartner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'coupleId': coupleId,
      'content': content,
      'imageUrls': imageUrls,
      'isLocalImages': isLocalImages,  // 추가된 필드
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likeCount': likeCount,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'isLikedByPartner': isLikedByPartner,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? coupleId,
    String? content,
    List<String>? imageUrls,
    bool? isLocalImages,  // 추가된 필드
    DateTime? createdAt,
    int? likeCount,
    List<Comment>? comments,
    bool? isLikedByPartner,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coupleId: coupleId ?? this.coupleId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      isLocalImages: isLocalImages ?? this.isLocalImages,  // 추가된 필드
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      comments: comments ?? this.comments,
      isLikedByPartner: isLikedByPartner ?? this.isLikedByPartner,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userImageUrl;
  final String username;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userImageUrl,
    required this.username,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      userImageUrl: json['userImageUrl'] as String?,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'userImageUrl': userImageUrl,
      'username': username,
    };
  }
}
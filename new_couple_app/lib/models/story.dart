class Story {
  final String id;
  final String userId;
  final String coupleId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String missionId;
  final String missionTitle;
  final bool isViewed;

  Story({
    required this.id,
    required this.userId,
    required this.coupleId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.missionId,
    required this.missionTitle,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['userId'] as String,
      coupleId: json['coupleId'] as String,
      imageUrl: json['imageUrl'] as String,
      caption: json['caption'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      missionId: json['missionId'] as String,
      missionTitle: json['missionTitle'] as String,
      isViewed: json['isViewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'coupleId': coupleId,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'missionId': missionId,
      'missionTitle': missionTitle,
      'isViewed': isViewed,
    };
  }

  Story copyWith({
    String? id,
    String? userId,
    String? coupleId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? missionId,
    String? missionTitle,
    bool? isViewed,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coupleId: coupleId ?? this.coupleId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      missionId: missionId ?? this.missionId,
      missionTitle: missionTitle ?? this.missionTitle,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class Mission {
  final String id;
  final String title;
  final String description;
  final int rewardAmount;
  final bool isActive;
  final DateTime date;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    this.rewardAmount = 10,
    this.isActive = true,
    required this.date,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rewardAmount: json['rewardAmount'] as int? ?? 10,
      isActive: json['isActive'] as bool? ?? true,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'isActive': isActive,
      'date': date.millisecondsSinceEpoch,
    };
  }
}
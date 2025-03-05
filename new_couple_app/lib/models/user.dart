class User {
  final String id;
  final String email;
  final String username;
  final String? profileImageUrl;
  final String? partnerId;
  final String? coupleId;
  final DateTime createdAt;
  final int currency;
  final DateTime? relationshipStartDate;
  final DateTime? partnerBirthday;
  final DateTime? menstrualCycleStart;
  final int menstrualCycleDuration;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.partnerId,
    this.coupleId,
    required this.createdAt,
    this.currency = 0,
    this.relationshipStartDate,
    this.partnerBirthday,
    this.menstrualCycleStart,
    this.menstrualCycleDuration = 28,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      partnerId: json['partnerId'] as String?,
      coupleId: json['coupleId'] as String?,
      createdAt: (json['createdAt'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      relationshipStartDate: json['relationshipStartDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['relationshipStartDate'] as int)
          : null,
      partnerBirthday: json['partnerBirthday'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['partnerBirthday'] as int)
          : null,
      menstrualCycleStart: json['menstrualCycleStart'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['menstrualCycleStart'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'partnerId': partnerId,
      'coupleId': coupleId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'currency': currency,
      'relationshipStartDate': relationshipStartDate?.millisecondsSinceEpoch,
      'partnerBirthday': partnerBirthday?.millisecondsSinceEpoch,
      'menstrualCycleStart': menstrualCycleStart?.millisecondsSinceEpoch,
      'menstrualCycleDuration': menstrualCycleDuration,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? profileImageUrl,
    String? partnerId,
    String? coupleId,
    DateTime? createdAt,
    int? currency,
    DateTime? relationshipStartDate,
    DateTime? partnerBirthday,
    DateTime? menstrualCycleStart,
    int? menstrualCycleDuration,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      partnerId: partnerId ?? this.partnerId,
      coupleId: coupleId ?? this.coupleId,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      relationshipStartDate: relationshipStartDate ?? this.relationshipStartDate,
      partnerBirthday: partnerBirthday ?? this.partnerBirthday,
      menstrualCycleStart: menstrualCycleStart ?? this.menstrualCycleStart,
      menstrualCycleDuration: menstrualCycleDuration ?? this.menstrualCycleDuration,
    );
  }
}

extension Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
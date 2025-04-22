enum EventType {
  date,
  anniversary,
  birthday,
  menstruation,
  other
}

extension EventTypeExtension on EventType {
  String get name {
    switch (this) {
      case EventType.date:
        return 'Date';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.birthday:
        return 'Birthday';
      case EventType.menstruation:
        return 'Menstruation';
      case EventType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case EventType.date:
        return 'assets/images/date_icon.png';
      case EventType.anniversary:
        return 'assets/images/anniversary_icon.png';
      case EventType.birthday:
        return 'assets/images/birthday_icon.png';
      case EventType.menstruation:
        return 'assets/images/menstruation_icon.png';
      case EventType.other:
        return 'assets/images/other_icon.png';
    }
  }

  String get color {
    switch (this) {
      case EventType.date:
        return '#FF6B6B'; // Red
      case EventType.anniversary:
        return '#4ECDC4'; // Teal
      case EventType.birthday:
        return '#FFD166'; // Yellow
      case EventType.menstruation:
        return '#FF9999'; // Light Pink
      case EventType.other:
        return '#6B66FF'; // Purple
    }
  }
}

class CalendarEvent {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final EventType type;
  final bool isRecurring;
  final RecurrenceRule? recurrenceRule;
  final String? location;
  final String createdByUserId;
  final DateTime createdAt;
  final List<String> reminders; // List of times in minutes before event

  CalendarEvent({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    required this.type,
    this.isRecurring = false,
    this.recurrenceRule,
    this.location,
    required this.createdByUserId,
    required this.createdAt,
    this.reminders = const [],
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      coupleId: json['coupleId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
      endDate: json['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int) 
          : null,
      isAllDay: json['isAllDay'] as bool? ?? false,
      type: EventType.values[json['type'] as int],
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceRule: json['recurrenceRule'] != null 
          ? RecurrenceRule.fromJson(json['recurrenceRule'] as Map<String, dynamic>) 
          : null,
      location: json['location'] as String?,
      createdByUserId: json['createdByUserId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      reminders: (json['reminders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coupleId': coupleId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isAllDay': isAllDay,
      'type': type.index,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule?.toJson(),
      'location': location,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reminders': reminders,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? coupleId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    EventType? type,
    bool? isRecurring,
    RecurrenceRule? recurrenceRule,
    String? location,
    String? createdByUserId,
    DateTime? createdAt,
    List<String>? reminders,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      location: location ?? this.location,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      reminders: reminders ?? this.reminders,
    );
  }
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime? until;
  final int? count;
  final List<int>? byWeekDays; // 1-7 (Monday-Sunday)
  final List<int>? byMonthDays; // 1-31

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byWeekDays,
    this.byMonthDays,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values[json['frequency'] as int],
      interval: json['interval'] as int? ?? 1,
      until: json['until'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['until'] as int) 
          : null,
      count: json['count'] as int?,
      byWeekDays: (json['byWeekDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      byMonthDays: (json['byMonthDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.index,
      'interval': interval,
      'until': until?.millisecondsSinceEpoch,
      'count': count,
      'byWeekDays': byWeekDays,
      'byMonthDays': byMonthDays,
    };
  }
}
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:new_couple_app/models/calendar_event.dart';
import 'package:new_couple_app/models/user.dart';
import 'package:new_couple_app/services/auth_service.dart';

class CalendarService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  
  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  CalendarService({AuthService? authService})
      : _authService = authService ?? AuthService();
  
  Future<void> loadEvents({DateTime? startDate, DateTime? endDate}) async {
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
      QuerySnapshot snapshot;
      
      if (startDate != null && endDate != null) {
        // Query with date range
        snapshot = await _firestore
            .collection('events')
            .where('coupleId', isEqualTo: coupleId)
            .where('startDate', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
            .where('startDate', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
            .get();
      } else {
        // Query all events
        snapshot = await _firestore
            .collection('events')
            .where('coupleId', isEqualTo: coupleId)
            .get();
      }
      
      _events = snapshot.docs
          .map((doc) => CalendarEvent.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort events by start date
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      await _addAutomaticEvents();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _addAutomaticEvents() async {
    try {
      if (_authService.currentUser == null) return;
      
      final User? currentUser = _authService.currentUser;
      final User? partner = await _authService.getPartnerInfo();
      
      if (currentUser == null || partner == null) return;
      
      // Add automatic events like menstrual cycles, anniversaries, etc.
      final List<CalendarEvent> automaticEvents = [];
      
      // Add menstrual cycle events if available
      if (currentUser.menstrualCycleStart != null) {
        automaticEvents.addAll(_generateMenstrualCycleEvents(
          currentUser.menstrualCycleStart!,
          currentUser.menstrualCycleDuration,
          currentUser.id,
          currentUser.coupleId!,
        ));
      }
      
      // Add relationship anniversary events if available
      if (currentUser.relationshipStartDate != null) {
        automaticEvents.addAll(_generateAnniversaryEvents(
          currentUser.relationshipStartDate!,
          currentUser.id,
          currentUser.coupleId!,
        ));
      }
      
      // Add partner birthday if available
      if (currentUser.partnerBirthday != null) {
        final DateTime now = DateTime.now();
        final DateTime thisYearBirthday = DateTime(
          now.year,
          currentUser.partnerBirthday!.month,
          currentUser.partnerBirthday!.day,
        );
        
        if (thisYearBirthday.isAfter(now)) {
          automaticEvents.add(CalendarEvent(
            id: 'birthday_${partner.id}_${now.year}',
            coupleId: currentUser.coupleId!,
            title: '${partner.username}\'s Birthday',
            startDate: thisYearBirthday,
            isAllDay: true,
            type: EventType.birthday,
            createdByUserId: 'system',
            createdAt: DateTime.now(),
          ));
        }
        
        final DateTime nextYearBirthday = DateTime(
          now.year + 1,
          currentUser.partnerBirthday!.month,
          currentUser.partnerBirthday!.day,
        );
        
        automaticEvents.add(CalendarEvent(
          id: 'birthday_${partner.id}_${now.year + 1}',
          coupleId: currentUser.coupleId!,
          title: '${partner.username}\'s Birthday',
          startDate: nextYearBirthday,
          isAllDay: true,
          type: EventType.birthday,
          createdByUserId: 'system',
          createdAt: DateTime.now(),
        ));
      }
      
      // Add automatic events to the events list (avoiding duplicates)
      for (final event in automaticEvents) {
        if (!_events.any((e) => e.id == event.id)) {
          _events.add(event);
        }
      }
      
      // Re-sort events
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
    } catch (e) {
      print('Failed to add automatic events: ${e.toString()}');
    }
  }
  
  List<CalendarEvent> _generateMenstrualCycleEvents(
    DateTime startDate,
    int cycleDuration,
    String userId,
    String coupleId,
  ) {
    final List<CalendarEvent> events = [];
    final DateTime now = DateTime.now();
    final DateTime sixMonthsLater = now.add(const Duration(days: 180));
    
    // Start from the most recent cycle before now
    DateTime cycleStartDate = startDate;
    while (cycleStartDate.isBefore(now)) {
      cycleStartDate = cycleStartDate.add(Duration(days: cycleDuration));
    }
    
    // Go back one cycle to get the current/most recent cycle
    cycleStartDate = cycleStartDate.subtract(Duration(days: cycleDuration));
    
    // Generate events for the next 6 months
    while (cycleStartDate.isBefore(sixMonthsLater)) {
      // Period duration is typically 5-7 days
      final DateTime periodEndDate = cycleStartDate.add(const Duration(days: 5));
      
      events.add(CalendarEvent(
        id: 'menstrual_${userId}_${cycleStartDate.millisecondsSinceEpoch}',
        coupleId: coupleId,
        title: 'Period',
        startDate: cycleStartDate,
        endDate: periodEndDate,
        isAllDay: true,
        type: EventType.menstruation,
        createdByUserId: 'system',
        createdAt: DateTime.now(),
      ));
      
      // Move to next cycle
      cycleStartDate = cycleStartDate.add(Duration(days: cycleDuration));
    }
    
    return events;
  }
  
  List<CalendarEvent> _generateAnniversaryEvents(
    DateTime startDate,
    String userId,
    String coupleId,
  ) {
    final List<CalendarEvent> events = [];
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int relationshipYears = currentYear - startDate.year + 1;
    
    // Generate anniversary events for this year and next year
    for (int year = currentYear; year <= currentYear + 1; year++) {
      final DateTime anniversaryDate = DateTime(
        year,
        startDate.month,
        startDate.day,
      );
      
      if (anniversaryDate.isBefore(now) && year == currentYear) {
        // Skip if this year's anniversary has already passed
        continue;
      }
      
      final int yearsCount = year - startDate.year;
      
      events.add(CalendarEvent(
        id: 'anniversary_${coupleId}_${year}',
        coupleId: coupleId,
        title: '$yearsCount${_getOrdinalSuffix(yearsCount)} Anniversary',
        startDate: anniversaryDate,
        isAllDay: true,
        type: EventType.anniversary,
        createdByUserId: 'system',
        createdAt: DateTime.now(),
      ));
      
      // Add monthly anniversaries for the first year
      if (relationshipYears <= 1) {
        for (int month = 1; month <= 11; month++) {
          final int targetMonth = (startDate.month + month) % 12;
          final int targetYear = (startDate.month + month) > 12 ? year + 1 : year;
          
          final DateTime monthlyDate = DateTime(
            targetYear,
            targetMonth == 0 ? 12 : targetMonth,
            startDate.day,
          );
          
          if (monthlyDate.isBefore(now)) {
            // Skip if this monthly anniversary has already passed
            continue;
          }
          
          events.add(CalendarEvent(
            id: 'monthly_anniversary_${coupleId}_${monthlyDate.millisecondsSinceEpoch}',
            coupleId: coupleId,
            title: '$month ${_getOrdinalSuffix(month)} Month Anniversary',
            startDate: monthlyDate,
            isAllDay: true,
            type: EventType.anniversary,
            createdByUserId: 'system',
            createdAt: DateTime.now(),
          ));
        }
      }
    }
    
    return events;
  }
  
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
  
  Future<bool> createEvent(
    String title,
    DateTime startDate,
    DateTime? endDate,
    bool isAllDay,
    EventType type,
    String? description,
    String? location,
    bool isRecurring,
    RecurrenceRule? recurrenceRule,
    List<String> reminders,
  ) async {
    if (_authService.currentUser == null || _authService.currentUser!.coupleId == null) {
      _error = 'User not connected with a partner';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final String eventId = const Uuid().v4();
      
      final CalendarEvent newEvent = CalendarEvent(
        id: eventId,
        coupleId: _authService.currentUser!.coupleId!,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        type: type,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        location: location,
        createdByUserId: _authService.currentUser!.id,
        createdAt: DateTime.now(),
        reminders: reminders,
      );
      
      await _firestore.collection('events').doc(eventId).set(newEvent.toJson());
      
      // Add to local list
      _events.add(newEvent);
      
      // Re-sort events
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateEvent(
    String eventId,
    String title,
    DateTime startDate,
    DateTime? endDate,
    bool isAllDay,
    EventType type,
    String? description,
    String? location,
    bool isRecurring,
    RecurrenceRule? recurrenceRule,
    List<String> reminders,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find event index
      final int index = _events.indexWhere((event) => event.id == eventId);
      if (index == -1) {
        _error = 'Event not found';
        return false;
      }
      
      final CalendarEvent oldEvent = _events[index];
      
      // Check if user has permission to edit (system events cannot be edited)
      if (oldEvent.createdByUserId == 'system') {
        _error = 'System events cannot be edited';
        return false;
      }
      
      // Update event
      final CalendarEvent updatedEvent = CalendarEvent(
        id: eventId,
        coupleId: oldEvent.coupleId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        type: type,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        location: location,
        createdByUserId: oldEvent.createdByUserId,
        createdAt: oldEvent.createdAt,
        reminders: reminders,
      );
      
      await _firestore.collection('events').doc(eventId).update(updatedEvent.toJson());
      
      // Update local list
      _events[index] = updatedEvent;
      
      // Re-sort events
      _events.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find event index
      final int index = _events.indexWhere((event) => event.id == eventId);
      if (index == -1) {
        _error = 'Event not found';
        return false;
      }
      
      final CalendarEvent event = _events[index];
      
      // Check if user has permission to delete (system events cannot be deleted)
      if (event.createdByUserId == 'system') {
        _error = 'System events cannot be deleted';
        return false;
      }
      
      // Delete event document
      await _firestore.collection('events').doc(eventId).delete();
      
      // Remove from local list
      _events.removeAt(index);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<CalendarEvent> getEventsForDate(DateTime date) {
    final DateTime dayStart = DateTime(date.year, date.month, date.day);
    final DateTime dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _events.where((event) {
      if (event.isAllDay) {
        // For all-day events, check if the day matches
        return (event.startDate.year == date.year &&
                event.startDate.month == date.month &&
                event.startDate.day == date.day) ||
               (event.endDate != null &&
                dayStart.isAfter(event.startDate) &&
                dayStart.isBefore(event.endDate!));
      } else {
        // For timed events, check if it falls within the day
        return (event.startDate.isAfter(dayStart) && event.startDate.isBefore(dayEnd)) ||
               (event.endDate != null &&
                event.endDate!.isAfter(dayStart) &&
                event.startDate.isBefore(dayEnd));
      }
    }).toList();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
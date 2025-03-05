import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/calendar_service.dart';
import 'package:new_couple_app/models/calendar_event.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';
import 'package:new_couple_app/widgets/common/error_dialog.dart';
import 'package:new_couple_app/widgets/calendar/event_list_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    final calendarService = Provider.of<CalendarService>(context, listen: false);
    
    // Load events for 3 months before and after the current month
    final DateTime startDate = DateTime(_focusedDay.year, _focusedDay.month - 3, 1);
    final DateTime endDate = DateTime(_focusedDay.year, _focusedDay.month + 4, 0);
    
    await calendarService.loadEvents(startDate: startDate, endDate: endDate);
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }
  
  Future<void> _refreshData() async {
    await _loadEvents();
  }
  
  void _showEventEditor({CalendarEvent? event}) {
    Navigator.pushNamed(
      context,
      '/event-editor',
      arguments: event,
    ).then((_) => _refreshData());
  }
  
  @override
  Widget build(BuildContext context) {
    final calendarService = Provider.of<CalendarService>(context);
    
    if (calendarService.error != null) {
      return ErrorDialog(message: calendarService.error!, onRetry: _refreshData);
    }
    
    if (calendarService.isLoading) {
      return const LoadingIndicator();
    }
    
    final selectedDayEvents = calendarService.getEventsForDate(_selectedDay);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEventEditor(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget
          _buildCalendar(calendarService),
          
          // Selected day title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDay),
                  style: AppTheme.subheadingStyle,
                ),
                Text(
                  '${selectedDayEvents.length} Events',
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ),
          
          // Events list
          Expanded(
            child: selectedDayEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No events for this day',
                          style: AppTheme.bodyStyle,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showEventEditor(),
                          child: const Text('Add Event'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedDayEvents[index];
                      return EventListItem(
                        event: event,
                        onTap: () => _showEventEditor(event: event),
                        onDelete: event.createdByUserId != 'system'
                            ? () => calendarService.deleteEvent(event.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCalendar(CalendarService calendarService) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      eventLoader: (day) {
        return calendarService.getEventsForDate(day);
      },
      onDaySelected: _onDaySelected,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        
        // Load new events when page changes
        final DateTime startDate = DateTime(focusedDay.year, focusedDay.month - 1, 1);
        final DateTime endDate = DateTime(focusedDay.year, focusedDay.month + 2, 0);
        
        calendarService.loadEvents(startDate: startDate, endDate: endDate);
      },
      calendarStyle: CalendarStyle(
        // Weekend days style
        weekendTextStyle: const TextStyle(color: Colors.red),
        weekendDecoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        
        // Selected day
        selectedDecoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        
        // Today
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(color: Colors.white),
        
        // Days with events
        markerDecoration: const BoxDecoration(
          color: AppTheme.accentColor,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 5.0,
        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
      ),
    );
  }
}
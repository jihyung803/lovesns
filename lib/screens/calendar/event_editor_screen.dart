import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:new_couple_app/config/app_theme.dart';
import 'package:new_couple_app/services/calendar_service.dart';
import 'package:new_couple_app/models/calendar_event.dart';
import 'package:new_couple_app/widgets/common/loading_indicator.dart';

class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({Key? key}) : super(key: key);

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  
  bool _isAllDay = false;
  EventType _eventType = EventType.date;
  bool _isRecurring = false;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.monthly;
  int _recurrenceInterval = 1;
  
  List<String> _reminders = ['30'];  // Default 30 minutes before
  
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _eventId;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEventData();
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  void _initializeEventData() {
    final CalendarEvent? event = ModalRoute.of(context)?.settings.arguments as CalendarEvent?;
    
    if (event != null) {
      setState(() {
        _isEditMode = true;
        _eventId = event.id;
        _titleController.text = event.title;
        _descriptionController.text = event.description ?? '';
        _locationController.text = event.location ?? '';
        _startDate = event.startDate;
        _startTime = TimeOfDay(
          hour: event.startDate.hour,
          minute: event.startDate.minute,
        );
        _endDate = event.endDate;
        _endTime = event.endDate != null
            ? TimeOfDay(
                hour: event.endDate!.hour,
                minute: event.endDate!.minute,
              )
            : null;
        _isAllDay = event.isAllDay;
        _eventType = event.type;
        _isRecurring = event.isRecurring;
        _recurrenceFrequency = event.recurrenceRule?.frequency ?? RecurrenceFrequency.monthly;
        _recurrenceInterval = event.recurrenceRule?.interval ?? 1;
        _reminders = event.reminders;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime initialDate = type == 'start' ? _startDate : _endDate ?? _startDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: type == 'end' ? _startDate : DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (type == 'start') {
          _startDate = picked;
          
          // If end date is before start date, update it
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, String type) async {
    final TimeOfDay initialTime = type == 'start' ? _startTime : _endTime ?? _startTime;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (type == 'start') {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
  
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final calendarService = Provider.of<CalendarService>(context, listen: false);
      
      // Prepare dates
      final DateTime startDateTime = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : _combineDateAndTime(_startDate, _startTime);
      
      DateTime? endDateTime;
      if (_endDate != null) {
        endDateTime = _isAllDay
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : _combineDateAndTime(_endDate!, _endTime ?? _startTime);
      }
      
      // Prepare recurrence rule
      RecurrenceRule? recurrenceRule;
      if (_isRecurring) {
        recurrenceRule = RecurrenceRule(
          frequency: _recurrenceFrequency,
          interval: _recurrenceInterval,
        );
      }
      
      // Create or update event
      bool success;
      if (_isEditMode && _eventId != null) {
        success = await calendarService.updateEvent(
          _eventId!,
          _titleController.text,
          startDateTime,
          endDateTime,
          _isAllDay,
          _eventType,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          _locationController.text.isEmpty ? null : _locationController.text,
          _isRecurring,
          recurrenceRule,
          _reminders,
        );
      } else {
        success = await calendarService.createEvent(
          _titleController.text,
          startDateTime,
          endDateTime,
          _isAllDay,
          _eventType,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          _locationController.text.isEmpty ? null : _locationController.text,
          _isRecurring,
          recurrenceRule,
          _reminders,
        );
      }
      
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save event: ${calendarService.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save event: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedReminderTime = '30';
        
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: DropdownButtonFormField<String>(
            value: selectedReminderTime,
            decoration: const InputDecoration(
              labelText: 'Remind me before',
            ),
            items: [
              const DropdownMenuItem(value: '0', child: Text('At time of event')),
              const DropdownMenuItem(value: '5', child: Text('5 minutes before')),
              const DropdownMenuItem(value: '10', child: Text('10 minutes before')),
              const DropdownMenuItem(value: '15', child: Text('15 minutes before')),
              const DropdownMenuItem(value: '30', child: Text('30 minutes before')),
              const DropdownMenuItem(value: '60', child: Text('1 hour before')),
              const DropdownMenuItem(value: '120', child: Text('2 hours before')),
              const DropdownMenuItem(value: '1440', child: Text('1 day before')),
            ],
            onChanged: (value) {
              selectedReminderTime = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedReminderTime != null) {
                  setState(() {
                    if (!_reminders.contains(selectedReminderTime!)) {
                      _reminders.add(selectedReminderTime!);
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  void _removeReminder(String reminder) {
    setState(() {
      _reminders.remove(reminder);
    });
  }
  
  String _formatReminderText(String minutes) {
    final int mins = int.parse(minutes);
    if (mins == 0) {
      return 'At time of event';
    } else if (mins < 60) {
      return '$mins minutes before';
    } else if (mins == 60) {
      return '1 hour before';
    } else if (mins < 1440) {
      return '${mins ~/ 60} hours before';
    } else {
      return '${mins ~/ 1440} days before';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Saving event...'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Event' : 'New Event'),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Event type
            DropdownButtonFormField<EventType>(
              value: _eventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: EventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _eventType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // All day toggle
            SwitchListTile(
              title: const Text('All Day'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                });
              },
            ),
            const Divider(),
            
            // Date and time selection
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, 'start'),
            ),
            
            if (!_isAllDay)
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, 'start'),
              ),
            
            const Divider(),
            
            // End date and time (optional)
            SwitchListTile(
              title: const Text('End Date/Time'),
              value: _endDate != null,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _endDate = _startDate;
                    _endTime = _startTime;
                  } else {
                    _endDate = null;
                    _endTime = null;
                  }
                });
              },
            ),
            
            if (_endDate != null)
              ListTile(
                title: const Text('End Date'),
                subtitle: Text(DateFormat('MMM d, yyyy').format(_endDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'end'),
              ),
            
            if (_endDate != null && !_isAllDay)
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(_endTime?.format(context) ?? _startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, 'end'),
              ),
            
            const Divider(),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            
            // Recurrence settings
            ExpansionTile(
              title: const Text('Recurrence'),
              leading: const Icon(Icons.repeat),
              children: [
                SwitchListTile(
                  title: const Text('Repeat Event'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                ),
                if (_isRecurring) ...[
                  ListTile(
                    title: const Text('Frequency'),
                    trailing: DropdownButton<RecurrenceFrequency>(
                      value: _recurrenceFrequency,
                      onChanged: (value) {
                        setState(() {
                          _recurrenceFrequency = value!;
                        });
                      },
                      items: RecurrenceFrequency.values.map((frequency) {
                        String text;
                        switch (frequency) {
                          case RecurrenceFrequency.daily:
                            text = 'Daily';
                            break;
                          case RecurrenceFrequency.weekly:
                            text = 'Weekly';
                            break;
                          case RecurrenceFrequency.monthly:
                            text = 'Monthly';
                            break;
                          case RecurrenceFrequency.yearly:
                            text = 'Yearly';
                            break;
                        }
                        return DropdownMenuItem(value: frequency, child: Text(text));
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    title: const Text('Repeat every'),
                    trailing: DropdownButton<int>(
                      value: _recurrenceInterval,
                      onChanged: (value) {
                        setState(() {
                          _recurrenceInterval = value!;
                        });
                      },
                      items: List.generate(10, (index) => index + 1).map((value) {
                        return DropdownMenuItem(value: value, child: Text('$value'));
                      }).toList(),
                    ),
                    subtitle: Text(_getRecurrenceIntervalText()),
                  ),
                ],
              ],
            ),
            const Divider(),
            
            // Reminders
            ExpansionTile(
              title: const Text('Reminders'),
              leading: const Icon(Icons.notifications),
              children: [
                ...List.generate(_reminders.length, (index) {
                  final reminder = _reminders[index];
                  return ListTile(
                    title: Text(_formatReminderText(reminder)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeReminder(reminder),
                    ),
                  );
                }),
                ListTile(
                  title: const Text('Add Reminder'),
                  leading: const Icon(Icons.add),
                  onTap: _addReminder,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getRecurrenceIntervalText() {
    switch (_recurrenceFrequency) {
      case RecurrenceFrequency.daily:
        return _recurrenceInterval == 1
            ? 'day'
            : '$_recurrenceInterval days';
      case RecurrenceFrequency.weekly:
        return _recurrenceInterval == 1
            ? 'week'
            : '$_recurrenceInterval weeks';
      case RecurrenceFrequency.monthly:
        return _recurrenceInterval == 1
            ? 'month'
            : '$_recurrenceInterval months';
      case RecurrenceFrequency.yearly:
        return _recurrenceInterval == 1
            ? 'year'
            : '$_recurrenceInterval years';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:new_couple_app/models/calendar_event.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class EventListItem extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const EventListItem({
    Key? key,
    required this.event,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get color for event type
    final eventColor = _getEventColor(event.type);
    
    // Format time
    final timeText = event.isAllDay
        ? 'All day'
        : '${DateFormat('h:mm a').format(event.startDate)}${event.endDate != null ? ' - ${DateFormat('h:mm a').format(event.endDate!)}' : ''}';

    final isSystemEvent = event.createdByUserId == 'system';
    
    // Build item
    Widget content = ListTile(
      leading: Container(
        width: 12,
        height: double.infinity,
        color: eventColor,
      ),
      title: Text(
        event.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (event.location != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    event.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          event.type.name,
          style: TextStyle(
            fontSize: 12,
            color: eventColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: onTap,
    );
    
    // If this event can be deleted, wrap it in a Slidable widget
    if (onDelete != null && !isSystemEvent) {
      content = Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: content,
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }
  
  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.date:
        return const Color(0xFFFF6B6B); // Red
      case EventType.anniversary:
        return const Color(0xFF4ECDC4); // Teal
      case EventType.birthday:
        return const Color(0xFFFFD166); // Yellow
      case EventType.menstruation:
        return const Color(0xFFFF9999); // Light Pink
      case EventType.other:
        return const Color(0xFF6B66FF); // Purple
    }
  }
}
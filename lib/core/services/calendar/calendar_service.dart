import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../features/installments/domain/entities/installment.dart';

/// Syncs installment due dates with the device calendar.
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  Future<bool> ensurePermission() async {
    final granted = await _plugin.hasPermissions();
    if (granted.isSuccess && granted.data == true) return true;
    final req = await _plugin.requestPermissions();
    return req.isSuccess && req.data == true;
  }

  Future<String?> _defaultCalendarId() async {
    final res = await _plugin.retrieveCalendars();
    final list = res.data;
    if (!res.isSuccess || list == null || list.isEmpty) return null;
    final writable = list.where((c) => c.isReadOnly == false).toList();
    final cal = writable.firstWhere(
      (c) => c.isDefault == true,
      orElse: () => writable.isNotEmpty ? writable.first : list.first,
    );
    return cal.id;
  }

  Future<String?> upsertEvent(Installment i) async {
    if (!await ensurePermission()) return null;
    final calId = await _defaultCalendarId();
    if (calId == null) return null;

    final start = tz.TZDateTime.from(i.dueDate, tz.local);
    final end = start.add(const Duration(hours: 1));

    final event = Event(
      calId,
      eventId: i.calendarEventId,
      title: 'Qest — ${i.title}',
      description: 'Amount: ${i.amount}\n${i.notes ?? ''}'.trim(),
      start: start,
      end: end,
      reminders: [
        Reminder(minutes: 60),
        Reminder(minutes: 24 * 60),
      ],
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null || !result.isSuccess) return null;
    return result.data;
  }

  Future<void> deleteEvent(Installment i) async {
    final eid = i.calendarEventId;
    if (eid == null) return;
    final calId = await _defaultCalendarId();
    if (calId == null) return;
    await _plugin.deleteEvent(calId, eid);
  }
}

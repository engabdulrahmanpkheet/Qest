import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../constants/app_constants.dart';
import '../../utils/quiet_hours.dart';
import '../../../features/installments/domain/entities/installment.dart';
import 'notification_payload.dart';

/// Stream of notification taps/actions surfaced to the UI layer.
class NotificationEvent {
  const NotificationEvent({
    required this.payload,
    required this.actionId,
  });
  final NotificationPayload payload;
  final String? actionId;
}

/// Wraps flutter_local_notifications and owns Qest's smart scheduling logic.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<NotificationEvent> _events =
      StreamController<NotificationEvent>.broadcast();
  Stream<NotificationEvent> get events => _events.stream;

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    await _createChannels();
    _initialised = true;
  }

  Future<void> _createChannels() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.channelReminders,
      'Gentle reminders',
      description: 'Pre-due reminders sent during active hours.',
      importance: Importance.defaultImportance,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.channelDueDay,
      'Due today',
      description: 'High-priority due-date notifications with actions.',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.channelOverdue,
      'Overdue',
      description: 'Overdue payment alerts.',
      importance: Importance.high,
    ));
  }

  void _onResponse(NotificationResponse r) {
    final p = NotificationPayload.decode(r.payload);
    if (p == null) return;
    _events.add(NotificationEvent(payload: p, actionId: r.actionId));
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse r) {
    // Background isolate handler. We forward via the static instance.
    final p = NotificationPayload.decode(r.payload);
    if (p == null) return;
    NotificationService.instance._events
        .add(NotificationEvent(payload: p, actionId: r.actionId));
  }

  /// Cancels every notification scheduled for [uuid].
  Future<void> cancelForInstallment(String uuid) async {
    final pending = await _plugin.pendingNotificationRequests();
    final hash = uuid.hashCode;
    for (final n in pending) {
      // Our id encoding starts with hash & 0x00FFFFFF (see _idFor below).
      if ((n.id & 0x00FFFFFF) == (hash & 0x00FFFFFF)) {
        await _plugin.cancel(n.id);
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// (Re)schedules the full reminder ladder for [i].
  ///
  /// - 3 days before due: 3 reminders/day inside [10,22).
  /// - On due day: high-priority with action buttons.
  /// - Honours [Installment.snoozedUntil] and skips if paid.
  Future<void> scheduleForInstallment(Installment i) async {
    await cancelForInstallment(i.uuid);
    if (i.isPaid) return;

    final now = DateTime.now();
    final due = i.dueDate;
    final snoozedUntil = i.snoozedUntil;

    // 3-day pre-due ladder.
    for (var d = AppConstants.remindersDaysBeforeDue; d >= 1; d--) {
      final day = DateTime(due.year, due.month, due.day)
          .subtract(Duration(days: d));
      if (day.isBefore(DateTime(now.year, now.month, now.day))) continue;
      final slots = spreadReminderSlots(day, AppConstants.remindersPerDay);
      for (var s = 0; s < slots.length; s++) {
        final at = clampToActiveHours(slots[s]);
        if (at.isBefore(now)) continue;
        if (snoozedUntil != null && at.isBefore(snoozedUntil)) continue;
        await _zonedSchedule(
          id: _idFor(i.uuid, salt: d * 10 + s),
          when: at,
          channel: AppConstants.channelReminders,
          title: i.title,
          body: _reminderBody(i, daysBefore: d),
          payload: NotificationPayload(
            installmentUuid: i.uuid,
            kind: 'reminder',
          ),
          actions: const [],
        );
      }
    }

    // Due-day high-priority with actions.
    final dueAt = clampToActiveHours(
      DateTime(due.year, due.month, due.day, 10),
    );
    if (dueAt.isAfter(now) &&
        (snoozedUntil == null || dueAt.isAfter(snoozedUntil))) {
      await _zonedSchedule(
        id: _idFor(i.uuid, salt: 999),
        when: dueAt,
        channel: AppConstants.channelDueDay,
        title: 'Did you pay ${i.title}?',
        body: 'Tap to confirm or open your payment app.',
        payload: NotificationPayload(installmentUuid: i.uuid, kind: 'due'),
        actions: const [
          AndroidNotificationAction(
            AppConstants.actionPaid,
            'Paid',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            AppConstants.actionNotYet,
            'Not yet',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            AppConstants.actionOpenApp,
            'Open app',
            showsUserInterface: true,
          ),
        ],
      );
    }
  }

  String _reminderBody(Installment i, {required int daysBefore}) {
    if (daysBefore == 1) {
      return 'Tomorrow — a small heads-up so it does not surprise you.';
    }
    return 'In $daysBefore days. Tap to review.';
  }

  Future<void> _zonedSchedule({
    required int id,
    required DateTime when,
    required String channel,
    required String title,
    required String body,
    required NotificationPayload payload,
    required List<AndroidNotificationAction> actions,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final android = AndroidNotificationDetails(
      channel,
      _channelLabel(channel),
      importance: channel == AppConstants.channelReminders
          ? Importance.defaultImportance
          : Importance.high,
      priority: channel == AppConstants.channelReminders
          ? Priority.defaultPriority
          : Priority.high,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier:
          channel == AppConstants.channelDueDay ? 'qest_due_actions' : null,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        NotificationDetails(android: android, iOS: ios),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload.encode(),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('schedule failed: $e\n$st');
    }
  }

  String _channelLabel(String id) => switch (id) {
        AppConstants.channelReminders => 'Reminders',
        AppConstants.channelDueDay => 'Due today',
        AppConstants.channelOverdue => 'Overdue',
        _ => 'Qest',
      };

  /// Build a deterministic 31-bit id from [uuid] + [salt].
  int _idFor(String uuid, {required int salt}) {
    final base = uuid.hashCode & 0x00FFFFFF;
    return base | ((salt & 0x7F) << 24);
  }
}

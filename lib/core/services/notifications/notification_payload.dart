import 'dart:convert';

/// Payload encoded into notification ID and `payload` JSON.
class NotificationPayload {
  const NotificationPayload({
    required this.installmentUuid,
    required this.kind,
  });

  /// 'reminder' (3-day window), 'due' (due day), 'overdue', 'snoozed'.
  final String kind;
  final String installmentUuid;

  String encode() => jsonEncode({'k': kind, 'u': installmentUuid});

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        kind: m['k'] as String,
        installmentUuid: m['u'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

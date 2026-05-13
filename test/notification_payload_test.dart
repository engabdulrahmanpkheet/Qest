import 'package:flutter_test/flutter_test.dart';
import 'package:qest/core/services/notifications/notification_payload.dart';

void main() {
  test('encode/decode round-trips', () {
    const p = NotificationPayload(installmentUuid: 'abc-123', kind: 'due');
    final encoded = p.encode();
    final decoded = NotificationPayload.decode(encoded);
    expect(decoded?.installmentUuid, 'abc-123');
    expect(decoded?.kind, 'due');
  });

  test('decode tolerates null and bad JSON', () {
    expect(NotificationPayload.decode(null), isNull);
    expect(NotificationPayload.decode('not-json'), isNull);
  });
}
